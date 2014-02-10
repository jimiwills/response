#!perl
# nu-evstats
use strict;
use warnings;
use Bio::MaxQuant::Evidence::Statistics;

my $file = shift @ARGV;
my $o = Bio::MaxQuant::Evidence::Statistics->new();
$o->parseEssentials(filename=>$file);
$o->saveEssentials(filename=>$file.'.essentials');
$o->logRatios();
$o->saveEssentials(filename=>$file.'.essentials.logged');


