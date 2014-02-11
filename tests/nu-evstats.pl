#!perl
# nu-evstats
use strict;
use warnings;
use Bio::MaxQuant::Evidence::Statistics;

use Data::Dumper;

my $file = shift @ARGV;
my $o = Bio::MaxQuant::Evidence::Statistics->new();
$o->loadEssentials(filename=>$file);
$o->fullComparison(threads=>4, callback => sub {
		my ($lp,$r) = @_;
		print STDERR "\n>>>>>>>> $lp...\n\n";
		print $lp, Dumper $r;
	});


