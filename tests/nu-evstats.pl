#!perl
# nu-evstats
use strict;
use warnings;
use Bio::MaxQuant::Evidence::Statistics;

use Data::Dumper;

my $file = shift @ARGV;
my $o = Bio::MaxQuant::Evidence::Statistics->new();
$o->{max_p} = 2;
$o->{min_p} = -2;
$o->loadEssentials(filename=>$file);

open(my $fh, '>results.txt') or die $!;
print $fh join("\t", qw/Protein Comparison p-value p-value(mad) /)."\n";
close($fh);
$o->fullComparison(threads=>4, callback => sub {
		my ($lp,$r) = @_;
		print STDERR "\n>>>>>>>> $lp...\n\n";
		open(my $fh, '>>results.txt') or die $!;
		foreach (keys %$r){
			print $fh join("\t", $lp, $_, $r->{$_}->{p_max}, $r->{$_}->{p_mad_max}),"\n";
		}
		close($fh);
		
	});

