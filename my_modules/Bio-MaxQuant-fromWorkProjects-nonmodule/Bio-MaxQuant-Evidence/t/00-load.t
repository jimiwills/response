#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bio::MaxQuant::Evidence' ) || print "Bail out!\n";
}

diag( "Testing Bio::MaxQuant::Evidence $Bio::MaxQuant::Evidence::VERSION, Perl $], $^X" );
