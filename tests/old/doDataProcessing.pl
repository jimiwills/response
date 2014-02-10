#!perl

#here we do the data processing...

use strict;

my %OPTS = @ARGV; # so it better have the right stuff in it!

if($OPTS{'evidence'}){
  # do some evidence stuff...
  processEvidenceFile($OPTS{'evidence'});
}

if($OPTS{'ratios'}){
  # do some stuff with a ratios file
  processRatiosFile($OPTS{'ratios'});
}

if($OPTS{'proteinGroups'}){
  # like ratios, but guess column names differently
  processProteinGroupsFile($OPTS{'proteinGroups');
}


sub processEvidenceFile {
  my ($fn) = @_;
}

sub processRatiosFile {
  my ($fn) = @_;
}

sub processProteinGroupdFile {
  my ($fn) = @_;
}

