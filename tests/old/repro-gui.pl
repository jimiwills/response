#!perl

use strict;
use Tk;
use Tk::NoteBook;
use Tk::Balloon;
use Tk::Tiler;

setupGUI(); 

MainLoop;


sub setupGUI {
  my $mw = new MainWindow;
  my $nb = $mw->NoteBook()->pack(-expand=>1,-fill=>'both');
  my $bl = $mw->Balloon();
  my $exchange = {}; # data exchange between pages
  $exchange->{'page1'} = setupPage1($nb->add("page1",-label=>"Data Setup"), $bl, $exchange);
  $exchange->{'page2'} = setupPage2($nb->add("page2",-label=>"Progress"), $bl, $exchange);
  $exchange->{'page3'} = setupPage3($nb->add("page3",-label=>"Results"), $bl, $exchange);
}

sub setupPage1 {
  my ($f,$b,$e) = @_;
  my $data = formRowGrid($f,$b, 

<<FORMBITS

/fileopen ratiofile: "Ratios File" ??The file containing your ratios in CSV or Text format??
/fileopen evfile: "Evidence File" ??If you are using MaxQuant, you can include your evidence file for more stats??
/radio logmydata:Yes "Log my data" [Yes;No] ??Uncheck if your ratios are already on log scale??
/radio repro:Calculate "Calculate reproducibility?" [Calculate;Skip] ??If you want, you can skip the reproducibility andjust calculate the results from your evidence file??
/radio repli:All "Replicate Combinations" [All;Arbitrary] ??Calculate responses and response differences using individual arbitrary replicate combinations (by number) or calculate all combinations (could take a while)??
FORMBITS

  );
  $f->Button(-text=>'Start',-command=>sub { dataProcessing($e); })->grid(-row=>1000,-column=>1);
}

sub setupPage2 {
  my ($f,$b,$e) = @_;
}

sub setupPage3 {
  my ($f,$b,$e) = @_;
}

sub dataProcessing {
}

=pod

=head1 formRowGrid

The idea behind this is that it takes a lot of lines to make a form
row, and it needn't!  All we need is a name, label, help text, and
maybe some options and default.

Format:

    /<type> <name>:<?default?> "<Label>" [<?options?>] ??Help text?? 

It all has to be on one line, but the order is flexible.

Eg:

    /text port:3389 "Port Number" ??Enter the port number here??

=cut


sub formRowGrid {
  my ($f, $b, $text) = @_;
  my $row = 0;
  my $data = {};

  my %types = (
    text => sub{ return shift()->Entry(-textvariable=>\$data->{shift()}) },
    fileopen => sub{ my ($f,$n,$o) = @_;
      my $fr = $f->Frame;
      $o = {} unless ref($o) eq 'HASH';
      $fr->Entry(-textvariable=>\$data->{$n})->pack(-side=>'left');
      $fr->Button(-text=>'...',-command=>sub {
        my $fn = $f->getOpenFile(%$o);
        $data->{$n} = $fn if $fn;
      })->pack(-side=>'left');
      return $fr;
    },
    radio => sub { my ($f,$n,$o) = @_;
      my $fr = $f->Frame;
      if(ref($o) eq 'ARRAY'){
        $o = {map {$_=>$_} @$o};
      }
      my $row = 0;
      foreach (keys %$o){
        $fr->Radiobutton(-text=>$o->{$_},-value=>$_,-variable=>\$data->{$n})->pack;
      }
      return $fr;
    }
  );

  foreach(split /\n/, $text){
    chomp;
    next unless $_;
    my    ($type, $name, $label, $helptext, $default, $options)
     = (qw( text noname nolabel     nohelp),      "",       "");
    $type = $1 if /\/(\w+)/;
    ($name,$default) = ($1,$2) if /(\w+)\:(\S*)/;
    $helptext = $1 if /\?\?(.*)\?\?/;
    $label = $1 if /"([^"]+)"/;
    $options = [split /;\s*/, $1] if /\[(.*)\]/;
    $options = { map {split /\:/} (split /;\s*/, $1) } if /\{(.*)\}/;
    
    $data->{$name} = $default;

    my @row = ();
    push @row, $f->Label(-text=>$label);
    die "type $type not defined" unless exists $types{$type};

    push @row, &{$types{$type}}($f,$name,$options);

    $row ++;
    my $col = 0;
    foreach my $e(@row){
      $e->grid(-row=>$row,-column=>$col++);
      $b->attach($e,-balloonmsg=>$helptext);
    }
    
  }
  # label, type/options, help
}



