#!perl
use strict;
use Tk::MDTextBook::Data2Tk;
data2tk;
__DATA__
MIME Version: 1.0
Content-Type: multipart/mixed; boundary=##--##--##--##--##
Custom-Header: stuff here
Title: Here's my title

Here is a prologue
--##--##--##--##--##
Content-Type: application/x-ptk.markdown
Title: _Basic MarkDown
ID: Page1

# MarkDown Tk Text Thingy.

Here is my markdown.  Here is some stuff in a preformatted block:

    field label    <Tk::Entry>   <-- put stuff here!
    another label  <Tk::Entry>   ... and more
    and so on      <Tk::Button -text="Here is some text!"> 

## Here is a sub-header

And a paragraph here
because I wanted to 
check that it handles stuff
right over several lines.


### Lists

* a 
* list
* here
** with
** a
** sublist
* inside!
** Here
*** is
**** up 
***** to
****** level 6 list
**** oh yeay!
** what?
* hm!


#### Tables

| and | here | this |
-----------
| is | a |table |
| which | will | probably |
| just| be |reformatted|

<Tk::Button -text="to page 2" -command=" Tk::MDTextBook::Data2Tk::raise('Page2'); ">

--##--##--##--##--##
Content-Type: application/x-ptk.markdown
Title: _Tk and Scripting
ID: Page2

##### Tk windows and scripts

Hmmm...

<? sub myNewSub { print "I'll be amazed if this works!\n" } ?>

<?= scalar gmtime(); ?>
  <Tk::Button -text="mybutton" -command=" myNewSub(); "> <Tk::Entry>


So, < ? means it's replaced within the Text, whereas < % is replaced before insertion...
the result is that < ? can be used for subroutines that buttons have access to and < % can be used for putting data in prior to formatting...

| here | is | a | table |
| %: | <%= scalar gmtime() %> | ?: | <?= scalar gmtime() ?>
| so | % aligns properly | but | ? does not!


###### Missing still...

Well, there's a lot that could be added...



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
