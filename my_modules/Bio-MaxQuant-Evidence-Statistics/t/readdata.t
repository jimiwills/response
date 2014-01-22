#!perl -T

use strict;
use warnings;
use Test::More::Behaviour;

BEGIN {
    use_ok('Bio::MaxQuant::Evidence::Statistics');
}

describe 'Bio::MaxQuant::Evidence::Statistics' => sub {
    context 'setup' => sub {
        it 'should be able to make a new object' => sub {
            my $o = Bio::MaxQuant::Evidence::Statistics->new();
        };
    };
    context 'parsing, saving and reloading essentials' => sub {
        my $O = Bio::MaxQuant::Evidence::Statistics->new();
        it 'should be ok' => sub {
            $O->parseEssentials(filename=>'t/selectedEvidence.txt');
        };
    };
    context 'always fail' => sub {
        it 'should always fail' => sub {
            ok(0, 'failing on purpose');
        };
    };
};
done_testing();
