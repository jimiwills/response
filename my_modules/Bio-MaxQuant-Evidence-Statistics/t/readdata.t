#!perl -T

use strict;
use warnings;
use Test::More::Behaviour;

BEGIN {
    use_ok('Bio::MaxQuant::Evidence::Statistics');
}

describe 'Bio::MaxQuant::Evidence::Statistics' => sub {
    my $medians = {
            'LCC1.nE.r1' => -1.63648125984708,
            'LCC1.nE.r2' => -0.760662584225348,
            'LCC1.nE.r3' => -1.17496248821031,
            'LCC1.wE.r1' => -1.75742769084347,
            'LCC1.wE.r2' => -1.48236893250806,
            'LCC1.wE.r3' => -1.35363466330692,
            'LCC1.ET.r1' => -1.16782156198554,
            'LCC1.ET.r2' => -0.799040767571155,
            'LCC1.ET.r3' => -1.40763147067625,
            'LCC9.nE.r1' => -1.37627215538279,
            'LCC9.nE.r2' => -1.49366210724807,
            'LCC9.nE.r3' => -1.01148411915581,
            'LCC9.wE.r1' => -1.03364967993477,
            'LCC9.wE.r2' => -0.849128423079465,
            'LCC9.wE.r3' => -0.67013012768234,
            'LCC9.ET.r1' => -1.6490049675735,
            'LCC9.ET.r2' => -1.7099059320793,
            'LCC9.ET.r3' => -0.954991099698264,
            'MCF7.nE.r1' => -0.163833476364181,
            'MCF7.nE.r2' => -0.842335352988528,
            'MCF7.nE.r3' => -0.648597816370036,
            'MCF7.wE.r1' => -0.672636102487885,
            'MCF7.wE.r2' => -0.961462164740981,
            'MCF7.wE.r3' => -0.53009319073457,
            'MCF7.ET.r1' => -1.30993649579144,
            'MCF7.ET.r2' => -1.15174663712211,
            'MCF7.ET.r3' => -0.986602137029225,
    };
    my $medians_exclude = { # exclude Q05655
            'LCC1.nE.r1' => -1.74714840094933,
            'LCC1.nE.r2' => -1.30854647839915,
            'LCC1.nE.r3' => -1.23917536507923,
            'LCC1.wE.r1' => -1.82679579543345,
            'LCC1.wE.r2' => -1.67865008344339,
            'LCC1.wE.r3' => -1.47995497596018,
            'LCC1.ET.r1' => -1.21641762605963,
            'LCC1.ET.r2' => -0.858410260758666,
            'LCC1.ET.r3' => -1.59459574635225,
            'LCC9.nE.r1' => -1.55681773300778,
            'LCC9.nE.r2' => -1.59864323359854,
            'LCC9.nE.r3' => -1.05336518102205,
            'LCC9.wE.r1' => -1.08389673806024,
            'LCC9.wE.r2' => -0.904035083866926,
            'LCC9.wE.r3' => -0.693084524258711,
            'LCC9.ET.r1' => -1.84032035065785,
            'LCC9.ET.r2' => -1.80783108999313,
            'LCC9.ET.r3' => -1.07704988169697,
            'MCF7.nE.r1' => -0.180331816503544,
            'MCF7.nE.r2' => -0.8763162516483,
            'MCF7.nE.r3' => -0.685639900752222,
            'MCF7.wE.r1' => -0.77450294428223,
            'MCF7.wE.r2' => -1.09501887210544,
            'MCF7.wE.r3' => -0.640086850310056,
            'MCF7.ET.r1' => -1.35969444568182,
            'MCF7.ET.r2' => -1.23677541432422,
            'MCF7.ET.r3' => -1.02698671387772,
    };
    my $medians_filter = { # only Q05655 and P11388
            'LCC1.nE.r1' => -2.0785027329921,
            'LCC1.nE.r2' => -1.75112517479158,
            'LCC1.nE.r3' => -1.30639485495392,
            'LCC1.wE.r1' => -1.439162508104,
            'LCC1.wE.r2' => -1.85897700227383,
            'LCC1.wE.r3' => -1.47196885525624,
            'LCC1.ET.r1' => -1.31981921569953,
            'LCC1.ET.r2' => -0.89598955383679,
            'LCC1.ET.r3' => -1.63285262534206,
            'LCC9.nE.r1' => -2.19945499829237,
            'LCC9.nE.r2' => -2.04775590586458,
            'LCC9.nE.r3' => -1.44772130900956,
            'LCC9.wE.r1' => -1.51682165421132,
            'LCC9.wE.r2' => -1.18737177007143,
            'LCC9.wE.r3' => -0.949839644352705,
            'LCC9.ET.r1' => -2.23487266034399,
            'LCC9.ET.r2' => -2.145669159723,
            'LCC9.ET.r3' => -1.1153139455028,
            'MCF7.nE.r1' => 0.664263458901235,
            'MCF7.nE.r2' => -0.0244901060161585,
            'MCF7.nE.r3' => 0.585635601362301,
            'MCF7.wE.r1' => 0.532763798157621,
            'MCF7.wE.r2' => 0.643038103450667,
            'MCF7.wE.r3' => 0.320542442428459,
            'MCF7.ET.r1' => -1.03215263684869,
            'MCF7.ET.r2' => -0.599624918592486,
            'MCF7.ET.r3' => -0.630974698103695,
    };
    my $ratios_individual = { # Q05655
            'LCC1.nE.r1' => -0.63509986575466,
            'LCC1.nE.r2' => -0.556789022536737,
            'LCC1.nE.r3' => -0.98459034333131,
            'LCC1.wE.r1' => -0.603708964185035,
            'LCC1.wE.r2' => -0.585366678188408,
            'LCC1.wE.r3' => -0.890733059997463,
            'LCC1.ET.r1' => -0.735619706777835,
            'LCC1.ET.r2' => -0.245762391293794,
            'LCC1.ET.r3' => -0.899695094204314,
            'LCC9.nE.r1' => 0.457226545544628,
            'LCC9.nE.r2' => 0.757620688778619,
            'LCC9.nE.r3' => -0.269787612886921,
            'LCC9.wE.r1' => 0.821334441348077,
            'LCC9.wE.r2' => 1.11648837917085,
            'LCC9.wE.r3' => 0.163852361197212,
            'LCC9.ET.r1' => -0.288135106038059,
            'LCC9.ET.r2' => 0.0322419242393385,
            'LCC9.ET.r3' => -0.278661026942532,
            'MCF7.nE.r1' => 1.09910969653997,
            'MCF7.nE.r2' => 0.688672738339143,
            'MCF7.nE.r3' => 1.45388831917853,
            'MCF7.wE.r1' => 0.450591031925189,
            'MCF7.wE.r2' => 0.52426431482084,
            'MCF7.wE.r3' => 0.818850560895434,
            'MCF7.ET.r1' => -0.589381276082298,
            'MCF7.ET.r2' => -0.168901948588134, # SD=0.357498874489868; MAD=0.236642882466628; SD via MAD=0.350847132598894; n=12
            'MCF7.ET.r3' => 0.273803945055041, # stdev=0.294588165594879 mad=0.19618609916723 sd-via-mad=0.290865838140269; n=10
            # ( MAD = 0.67449 SD;  SD = 1.4826016694 MAD )

    };
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
            is($o->logRatios(),1,'log ratios');
        };
        it 'should not log the ratios twice' => sub {
            is($o->logRatios(),0,'2nd try should fail');
        };
    };
    context 'normalization' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->logRatios(); # should be log 2!

        it 'should give median for a replicate' => sub {
            foreach my $rep(sort keys %$medians){
                is($o->replicateMedian(replicate=>$rep), $medians->{$rep}, "median for $rep");
            }
        };
        it 'should subtract median from all columns' => sub {
            is($o->replicateMedianSubtractions(), 1, 'replicate median subtractions');
        };
        it 'should allow median calculation on a filtered subset, e.g. reference proteins' => sub {
            foreach my $rep(sort keys %$medians_filter){
                is($o->replicateMedian(replicate=>$rep,filter=>[qw/Q05655 P11388/]), $medians_filter->{$rep}, "filter median for $rep");
            }
        };
        it 'should allow median on an excluded set, e.g. contaminants' => sub {
            foreach my $rep(sort keys %$medians_exclude){
                is($o->replicateMedian(replicate=>$rep,filter=>[qw/Q05655/]), $medians_exclude->{$rep}, "exclude median for $rep");
            }
        };
    };
    context 'individual spreads' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->logRatios(); # should be log 2!
        it 'should calculate ratio, MAD, SD, etc for each protein in each replicate' => sub {
            foreach my $rep(sort keys %$medians_individual){
                is($o->replicateMedian(replicate=>$rep,filter=>[qw/Q05655/]), $medians_individual->{$rep}, "individual median for $rep");
            }
            # R3 stdev=0.294588165594879 mad=0.19618609916723 sd-via-mad=0.290865838140269 n=10
            my $d = $o->replicateDeviations(replicate=>'MCF7.ET.r3',filter=>[qw/Q05655/]);
            is($d->{sd}, 0.294588165594879, 'standard deviation');
            is($d->{mad}, 0.19618609916723, 'median absolute deviation');
            is($d->{sd_via_mad}, 0.290865838140269, 'standard deviation via m.a.d.');
            is($d->{n}, 10, 'count');
            # R2 SD=0.357498874489868; MAD=0.236642882466628; SD via MAD=0.350847132598894; n=12
            my $d = $o->replicateDeviations(replicate=>'MCF7.ET.r2',filter=>[qw/Q05655/]);
            is($d->{sd}, 0.357498874489868, 'standard deviation');
            is($d->{mad}, 0.236642882466628, 'median absolute deviation');
            is($d->{sd_via_mad}, 0.350847132598894, 'standard deviation via m.a.d.');
            is($d->{n}, 12, 'count');
        };
    };
    context 'pairwise comparisons' => sub {
        it 'should give p-value for two items' => sub {
            #TTEST 0.7002150622
            is($o->ttest(replicate1=>'MCF7.ET.r2',replicate2=>'MCF7.ET.r3',filter=>[qw/Q05655/]), 0.7002150622, 'ttest p-value');
        };
        it 'should give maximum p-value among two sets of compared replicates' => sub {
            $o->experimentMaximumPvalue(experiment1=>'MCF7.ET',experiment2=>'MCF7.wE',filter=>[qw/Q05655/]);
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
