#!/usr/bin/perl

use strict;
use warnings;

=pod

Order of business...

Read in the experiment names (Ratio H/L <experimentname>) and 
delineate cells, conditions and replicates.

Set up the response analyses, i.e. pairwise comparisons between
all conditions with each cell line.

Set up differential response analyses, i.e. pairwise comparisons
of responses between cell lines.

Assumed separator is "." - but should be configurable.

So, A.x.1 means cell line A in condition x, replicate 1.

So we might set up:

A.x vs A.y for a response analysis, and call this A.x-y 
(note, the minus sign would become illegal in names)

and

A.x-y vs B.x-y for a differential response analysis, and
call this A-B.x-y.

=cut

use Data::Dumper;

my $pg = Bio::MaxQuant::ProteinGroups->new(
	filepath=>'../../Dropbox/Work/Projects/repro-evstats/response '
				. 'testdata rerun/good txt custom/proteinGroups.txt');
$pg->experiments;
print Dumper $pg;

package Bio::MaxQuant::ProteinGroups;

use strict;
use warnings;

use Carp;

use Statistics::Reproducibility;
use Text::CSV;
use IO::File;

sub new {
	my $p = shift;
	my $c = ref($p) || $p;
	my %defaults = (
		filepath => 'proteinGroups.txt',
		separator => '.',
	);
	my %opts = (%defaults, @_);

	my $o = {%opts};
	bless $o, $c;

	my $io = IO::File->new($opts{filepath}, 'r') 
		or die "Could not read $opts{filepath}: $!";
	my $csv = Text::CSV->new({sep_char=>"\t"});
	my $colref = $csv->getline($io);
	$csv->column_names (@$colref);

	$o->{csv} = $csv;
	$o->{io} = $io;
	$o->{header} = $colref;

	return $o;
}

sub experiments {
	my $o = shift;
	my @header = @{$o->{header}};
	my %celllines = ();
	my %conditions = ();
	my %replicates = ();
	my @expts = ();
	foreach (@header){
		next unless /^Experiment\s(\S+)$/;
		my $expt = $1;
		push @expts, $expt;
		my $dot1 = index($expt, $o->{separator});
		my $dot2 = index($expt, $o->{separator}, $dot1 + 1);
		my $cell = substr($expt,0,$dot1);
		my $cond = substr($expt,$dot1+1, $dot2-$dot1-1);
		my $repl = substr($expt, $dot2+1);
		return carp "bad experiment name format $_" unless 
			(defined $cell && defined $cond && defined $repl);
		$celllines{$cell} = 1;
		$conditions{$cond} = 1;
		$replicates{$repl} = 1;
	}
	$o->{expeiments} = \@expts;
	$o->{celllines} = [keys %celllines];
	$o->{conditions} = [keys %conditions];
	$o->{replicates} = [keys %replicates];
}



