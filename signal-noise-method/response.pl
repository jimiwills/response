#!/usr/bin/perl
use strict;
use warnings;
use Statistics::Reproducibility;
use Tk::MIMEApp::DataToTk;
use Bio::MaxQuant::ProteinGroups::Response;
use Bio::MaxQuant::Evidence::Statistics

print scalar *DATA;

data2tk;


__DATA__
MIME Version: 1.0
Content-Type: multipart/mixed; boundary=##--##--##--##--##
Title: Window Title

Prologue
--##--##--##--##--##
Content-Type: application/x-ptk.markdown
Title: _Processing
ID: Page1

# Here is some markdown...

--##--##--##--##--##
Content-Type: application/x-ptk.markdown
Title: _View Data
ID: Page2

# Here is some more markdown...

--##--##--##--##--##
Content-Type: application/x-yaml.menu

---
- _File:
  - _Exit: exit
- '---' : '---'  
- _Help:
  - _About: ResponseApp::ShowPreamble
  - _Help : ResponseApp::ShowEpilog 

--##--##--##--##--##
Content-Type: application/x-perl

package ResponseApp;

sub processProteinGroups {

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


sub getObjectList {
  my @shelf = @Tk::MIMEApp::Shelf;
  my $object = $shelf[$#shelf]; # get the last one!
  return $object->{Objects};
}

sub getMW {
  return $Tk::MIMEApp::DataToTk::MW;
}

sub getPreamble {
  return getObjectList()->{Main}->{Preamble};
}

sub getEpilog {
  return getObjectList()->{Main}->{Epilog};
}

sub ShowPreamble {
  getMW()->messageBox(-message=>getPreamble());
}

sub ShowEpilog {
  getMW()->messageBox(-message=>getEpilog());
}

--##--##--##--##--##--
Here is the epilogue

