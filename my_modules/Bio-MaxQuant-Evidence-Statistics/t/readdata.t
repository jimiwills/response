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
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        my $p = Bio::MaxQuant::Evidence::Statistics->new();
        it 'should parse a file' => sub {
            $o->parseEssentials(filename=>'t/selectedEvidence.txt');
        };
        it 'should have parsed the right number of proteins' => sub {
            is($o->proteinCount(), 7, 'counting proteins');
        };
        it 'should have parsed the correct protein ids and names' => sub {
            is( join(';', sort $o->proteinNames()), 
                '',
                'protein names');
            is( join(';', sort $o->proteinGroupIds()),
                '',
                'protein group ids'
            );
        };
        it 'should have the right number of experiments' => sub {
        };
        it 'should have the right number of evidences in experiments' => sub {
        };
        it 'should have the right number of shared evidences in experiments' => sub {
        };
        it 'should be able to serialize the data' => sub {
            $o->saveEssentials(filename=>'t/serialized');
        };
        it 'should have serialized the data correctly' => sub {
            # diff serialized and serialized.expected
        };
        it 'should be able to load serialized data' => sub {
            $p->saveEssentials(filename=>'t/serialized');
        };
        it 'should have correctly loaded serialized data' => sub {
            # deep comparison between $o and $p data.
        };
    };
    context 'always fail' => sub {
        it 'should always fail' => sub {
            ok(0, 'failing on purpose');
        };
    };
};
done_testing();
