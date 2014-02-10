#!perl
# nu-evstats
use strict;
use warnings;
use Bio::MaxQuant::Evidence::Statistics;

my $file = shift @ARGV;
my $o = Bio::MaxQuant::Evidence::Statistics->new();
$o->loadEssentials(filename=>$file);
my $fc = $o->fullComparison;

use Data::Dumper;
print Dumper $fc;


