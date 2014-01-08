#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Statistics::TheilSenEstimator' ) || print "Bail out!\n";
}

diag( "Testing Statistics::TheilSenEstimator $Statistics::TheilSenEstimator::VERSION, Perl $], $^X" );