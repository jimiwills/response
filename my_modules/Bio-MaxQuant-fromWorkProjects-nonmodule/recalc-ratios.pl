#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;

# example usage:
# perl recalc-ratios.pl -lineend LF -filter "Modified Sequence" "^[^W]+$" -expt_name "Raw File" -expt_group_pattern "\d{6}" evidence.txt
# default lineend is CRLF
# default expt_name is Experiment and default expt_group_pattern is .*
# there is no filter by default
# only unique peptides are considered.


# here we're using MaxQuant files, which should have line endings "\r\n" (CRLF)
$/ = "\r\n";

# names of columns we use...
my $id_name = 'id';
my $protein_groups_name = 'Protein Group IDs';
my $ratio_name = 'Ratio H/L';
my $expt_name = 'Experiment';
my $expt_group_pattern = '.*';
my %cols_req = ();  # to check the columns requested actually exist!

# filters and other command line options
my @filters = ();
print STDERR "ARGS:\n  ".join("\n  ",@ARGV)."\n";
while(@ARGV > 1){
	if($ARGV[0] eq '-filter'){
		shift @ARGV;
		my $k = shift @ARGV;
		my $v = shift @ARGV;
		push @filters, [$k,$v];
		$cols_req{$k} = 0; # filters use names too...
	}
	elsif($ARGV[0] eq '-pg_name'){
		shift @ARGV;
		$protein_groups_name = shift @ARGV;
	}
	elsif($ARGV[0] eq '-id_name'){
		shift @ARGV;
		$id_name = shift @ARGV;
	}
	elsif($ARGV[0] eq '-ratio_name'){
		shift @ARGV;
		$ratio_name = shift @ARGV;
	}
	elsif($ARGV[0] eq '-expt_name'){
		shift @ARGV;
		$expt_name = shift @ARGV;
	}
	elsif($ARGV[0] eq '-expt_group_pattern'){
		shift @ARGV;
		$expt_group_pattern = shift @ARGV;
	}
	elsif($ARGV[0] eq '-lineend'){
		shift @ARGV;
		my $le = shift @ARGV;
		if($le eq 'CRLF'){
			$/ = "\r\n";
		}
		elsif($le eq 'LFCR'){
			$/ = "\n\r";
		}
		elsif($le eq 'LF'){
			$/ = "\n";
		}
		elsif($le eq 'CR'){
			$/ = "\r";
		}
		else {
			print STDERR "Unrecognised line end: $le; falling back to CRLF\n";
			$/ = "\r\n";
		}
	}
	else {
		die "unrecognised argument: $ARGV[0]";
	}
}
if(@ARGV != 1){
	die "no filename given";
}

# check columns...
%cols_req = (%cols_req, $protein_groups_name=>0,$ratio_name=>0,$id_name=>0,$expt_name=>0,$expt_group_pattern=>0); 

# set up the file...
my ($fn) = @ARGV;
my $fh = IO::File->new($fn, 'r');
my $csv = Text::CSV->new ({ eol => $/, sep_char=>"\t" });
my $headerrow = $csv->getline ($fh);
$csv->column_names(@$headerrow);

## check columns...
foreach(@$headerrow){
	$cols_req{$_} = 1; # mark everything we've found
}
my $cols_not_ok = 0;
foreach(keys %cols_req){ # check everything requested...
	if(! $cols_req{$_}){ # if not marked as found...
		print STDERR "ERROR: column '$_' not found\n";
		$cols_not_ok = 1; # set flag
	}
}
if($cols_not_ok){ # flag set
	die "could not find one or more columns... columns found were:\n"
	. join("\t", map {"'$_'"} @$headerrow) . "\n";
}

# now get on with reading the file...
my %proteinGroups = ();
while(! eof($fh)){
	my $row = $csv->getline_hr ($fh);
	my $ok = 1;
	foreach my $f(@filters){
		my ($k,$v) = @$f;
		if($row->{$k} !~ /$v/){
			$ok = 0;
			last;
		}
	}
	next unless $ok;
	my $pgid = $row->{$protein_groups_name};
	next if $pgid =~ /;/;
	my $ratio = $row->{$ratio_name};
	next unless $ratio =~ /^[\d\.]+$/;
	my $id = $row->{$id_name};
	$proteinGroups{$pgid} = {} unless defined $proteinGroups{$pgid};
	$proteinGroups{$pgid}->{$id} = $ratio;
}

# now report...
print join("\t", $protein_groups_name, $ratio_name, 'Count', $id_name.'s', $ratio_name.'s')."\n";
foreach my $pgid(sort {$a <=> $b} keys %proteinGroups){
	my %ir = %{$proteinGroups{$pgid}};
	my @i = sort {$ir{$a} <=> $ir{$b}} keys %ir;
	my @r = map {$ir{$_}} @i;
	my $median = logmedian(@r);
	print join("\t",
		$pgid, $median,
		scalar(@i),
		join(';',@i),
		join(';',@r),
	)."\n";
}


#sub median {
#	return @_ % 2 ?
#		$_[int @_/2] :
#		(
#			$_[@_/2]
#		+	$_[@_/2 -1]
#		) / 2;
#}

sub logmedian {
	return @_ % 2 ?
		$_[int @_/2] :
		exp((
			log($_[@_/2])
		+	log($_[@_/2 -1])
		)/2);
}
