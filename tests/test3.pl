#!perl
use strict;
use Statistics::Reproducibility;
use Tk::MIMEApp::DataToTk;
data2tk;
__DATA__
MIME Version: 1.0
Content-Type: multipart/mixed; boundary=##--##--##--##--##
Title: Window Title

Here is a prologue
--##--##--##--##--##
Content-Type: application/x-ptk.markdown
Title: _Basic MarkDown
ID: Page1

# MarkDown Tk Text Thingy.

## Here is a sub-header

And a paragraph here
because I wanted to 
check that it handles stuff
right over several lines.

--##--##--##--##--##
Content-Type: application/x-ptk.markdown
Title: _Data
ID: Data

# Data setup

For this version of the program, you will need your data in one file.
At the moment, it only supports a file with each column containing an
experimental ratio.  Column names should be of the format <m>.<c>.<r>,
where <m> is the model, <c> is the experimental condition and <r> is 
the experimental replicate number.

Choose your file: <Tk::Entry -validate="all" -validatecommand="FileEntryValidate"> <Tk::Button -text="..." -command="FileChoose">

<? sub FileEntryValidate {} ?>
<? sub FileChoose { $myapp::filename = myapp::getMW()->getOpenFile(); } ?>

--##--##--##--##--##
Content-Type: application/x-yaml.menu

---
- _File:
  - _Exit: exit
- '---' : '---'  
- _Help:
  - _About: myapp::ShowPreamble
  - _Help : myapp::ShowEpilog 

--##--##--##--##--##
Content-Type: application/x-perl

package myapp;

sub myScriptSub {
  print "Hello from script sub!\n";
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
