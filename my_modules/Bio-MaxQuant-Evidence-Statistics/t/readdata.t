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
            is( join(';', sort $o->getLeadingProteins()), 
                'P03372;P11388;P41743;P49454;Q02880-2;Q05655;Q92547',
                'leading proteins');
            is( join(';', sort $o->getProteinGroupIds()),
                '1371;1485;1775;1846;2111;2131;2913',
                'protein group ids'
            );
        };
        it 'should have the right number of experiments and evidences' => sub {
            is( scalar($o->experiments), 27, 'experiments');
            is( scalar($o->ids), 2793, 'ids');
        };
        it 'should have the right number shared and unique' => sub {
            is( scalar($o->sharedIds), 400, 'shared');
            is( scalar($o->uniqueIds), 2393, 'unique');
        };
        it 'should be able to serialize the data' => sub {
            $o->saveEssentials(filename=>'t/serialized');
        };
        it 'should have serialized the data correctly' => sub {
            # diff serialized and serialized.expected??
        };
        it 'should be able to load serialized data' => sub {
            $p->loadEssentials(filename=>'t/serialized');
        };
        it 'should have correctly loaded serialized data' => sub {
            # deep comparison between $o and $p data??
            is($o->proteinCount(), 7, 'counting proteins');
            is( scalar($o->experiments), 27, 'experiments');
            is( scalar($o->ids), 2793, 'ids');
            is( scalar($o->sharedIds), 400, 'shared');
            is( scalar($o->uniqueIds), 2393, 'unique');
            is( join(';', sort $o->getLeadingProteins()), 
                'P03372;P11388;P41743;P49454;Q02880-2;Q05655;Q92547',
                'leading proteins');
            is( join(';', sort $o->getProteinGroupIds()),
                '1371;1485;1775;1846;2111;2131;2913',
                'protein group ids'
            );
        };
    };
    context 'data prep' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        it 'should log all the ratios' => sub {
        };
        it 'should not log the ratios twice' => sub {
        };
    };
    context 'normalization' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        it 'should give median for a column' => sub {
        };
        it 'should subtract median from all columns' => sub {
        };
        it 'should allow median calculation on a filtered subset, e.g. reference proteins' => sub {
        };
        it 'should allow median on an excluded set, e.g. contaminants' => sub {
        };
    };
    context 'individual spreads' => sub {
        it 'should calculate ratio, MAD, SD, etc for each protein in each replicate' => sub {
            
        };
    };
    context 'pairwise comparisons' => sub {
        it 'should give p-value for two items' => sub {
        };
        it 'should give maximum p-value among two sets of compared replicates' => sub {
        };
    };
    context 'differential response detection' => sub {
        it 'should compare orthogonal items' => sub {
        };
        it 'should report on threshold-breaking sets' => sub {
        };
    };
    context 'summary stats and p-values' => sub {
        it '' => sub {
        };
        it '' => sub {
        };
    };
    context 'always fail' => sub {
        it 'should always fail' => sub {
            ok(0, 'failing on purpose');
        };
    };
};
done_testing();
