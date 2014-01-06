#!perl
use strict;
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
Title: _Tk and Scripting
ID: Page2

##### Tk windows and scripts

Here is my markdown.  Here is some stuff in a preformatted block:

    field label    <Tk::Entry>   <-- put stuff here!
    another label  <Tk::Entry>   ... and more
    and so on      <Tk::Button -text="Here is some text!"> 

--##--##--##--##--##
Content-Type: application/x-yaml.menu

---
- _File:
  - _Exit: exit
- '---' : '---'  
- _Help:
  - _About: MyPackage::ShowPreamble
  - _Help : MyPackage::ShowEpilog 

--##--##--##--##--##
Content-Type: application/x-perl

package MyPackage;

sub myScriptSub {
  print "Hello from script sub!\n";
}

sub getObjectList {
  my @shelf = @Tk::MDTextBook::Shelf;
  my $object = $shelf[$#shelf]; # get the last one!
  return $object->{Objects};
}

sub getMW {
  return $Tk::MDTextBook::Data2Tk::MW;
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
