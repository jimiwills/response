#!/usr/bin/perl

use strict;
use warnings;

use Bio::MaxQuant::ProteinGroups::Response;


my $resp = Bio::MaxQuant::ProteinGroups::Response->new(
	filepath=>'../../Dropbox/Work/Projects/repro-evstats/response '
				. 'testdata rerun/good txt custom/proteinGroups.txt'
);

mkdir ('./test');
mkdir ('./test/replicate_comparisons');
mkdir ('./test/responses');
mkdir ('./test/differential_responses');

$resp->replicate_comparison(output_directory=>'./test/replicate_comparisons');
$resp->calculate_response_comparisons(output_directory=>'./test/responses');
$resp->calculate_differential_response_comparisons(output_directory=>'./test/differential_responses');




__END__

OLD STUFF HERE...


use Data::Dumper;
$Data::Dumper::Sortkeys = sub{
	return [sort keys %{$_[0]}];
};

my $Route = 3;
my $storefile = 'post-rescomps.stored';

if($Route == 1){

	my $pg = Bio::MaxQuant::ProteinGroups::Response->new(
		filepath=>'../../Dropbox/Work/Projects/repro-evstats/response '
					. 'testdata rerun/good txt custom/proteinGroups.txt');
	#my $rc = $pg->replicate_comparison(output_directory=>'rc');

	my $pts = $pg->calculate_response_comparisons();

	open(STORE,'>', $storefile) or die "Could not write $storefile: $!"; 
	print STORE Dumper $pg;
	close(STORE);
}
elsif($Route == 2){
	print STDERR "Reading storefile: $storefile...\n";
	open(STORE,'<', $storefile) or die "Could not read $storefile: $!";
	my $restore = $/; undef $/;
	my $toeval = <STORE>;
	$/ = $restore;
	close(STORE);
	print STDERR "evaling storefile...\n";
	my $VAR1;
	eval($toeval);
	my $pg = $VAR1;
	print STDERR "Done.\n";
	my $pts2 = $pg->calculate_differential_response_comparisons();

}
elsif ($Route == 3){

    my $resp = Bio::MaxQuant::ProteinGroups::Response->new(
		filepath=>'../../Dropbox/Work/Projects/repro-evstats/response '
					. 'testdata rerun/good txt custom/proteinGroups.txt'
    );

    mkdir ('./test');
    mkdir ('./test/replicate_comparisons');
    mkdir ('./test/responses');
    mkdir ('./test/differential_responses');

    $resp->replicate_comparison(output_directory=>'./test/replicate_comparisons');
	$resp->calculate_response_comparisons(output_directory=>'./test/responses');
	$resp->calculate_differential_response_comparisons(output_directory=>'./test/differential_responses');

}
