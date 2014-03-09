#!/usr/bin/perl
use strict;
use warnings;
use Statistics::Reproducibility;
use Tk::MIMEApp::DataToTk;
use Bio::MaxQuant::ProteinGroups::Response;
use Bio::MaxQuant::Evidence::Statistics;
use Tk::DirSelect;

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

# MaxQuant ProteinGroups Analysis

Choose ProteinGroups File: <? $app::proteinGroups = '...'; ?> <Tk::Button -textvariable="app::proteinGroups" -command="File1Button">
<? sub File1Button { $app::proteinGroups = ResponseApp::getMW()->getOpenFile(); } ?>

Choose Output Directory: <? $app::outputdir = '...'; ?> <Tk::Button -textvariable="app::outputdir" -command="Dir1Button">
<? sub Dir1Button {  $app::outputdir = ResponseApp::getMW()->DirSelect()->Show(); } ?>

<Tk::Button -text="Start Processing" -command="ProcessButton1">
<? sub ProcessButton1 { ResponseApp::processProteinGroups($app::proteinGroups, $app::outputdir); } ?>

<Tk::Button -text="View Output" -command="ViewButton1">
<? sub ViewButton1 { ResponseApp::viewResponse($app::outputdir); } ?>


# MaxQuant Evidence Analaysis

Choose Evidence File: <? $app::evidence = '...'; ?> <Tk::Button -textvariable="app::evidence" -command="File2Button">
<? sub File2Button { $app::evidence = ResponseApp::getMW()->getOpenFile(); } ?>




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

sub viewResponse {
	# folder checkboxes
	# file checkboxes (maybe organised in a grid?)
	# column checkboxes (maybe organised in a grid?) + summary stats here??
	# column filters
	# view columns v rows or rows v columns
	# saved view settings at buttons for rapid viewing
	# export current view
	# back/history?
}

sub processProteinGroups {
	my ($pgf,$od) = @_;

	my $resp = Bio::MaxQuant::ProteinGroups::Response->new(
		filepath=> $pgf 
	);

	mkdir ($od);
	mkdir ($od.'/replicate_comparisons');
	mkdir ($od.'/responses');
	mkdir ($od.'/differential_responses');

	$resp->replicate_comparison(output_directory=>$od.'/replicate_comparisons');
	$resp->calculate_response_comparisons(output_directory=>$od.'/responses');
	$resp->calculate_differential_response_comparisons(output_directory=>$od.'/differential_responses');


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

