#!perl

=pod

=head1 mdptk - markdown for perl/tk

This is to display markdown, but also to parse out bits of xml/yaml and use for paging (notepad), menus and scripting.

=head1 paging

It looks like this:

  <notebook>
  <page id="myid" label="whatever">

  # Markdown

  </page>
  </notebook>

If there's a notebook, there needs to be pages.


=head1 menus

It looks like this:

  <menu>
    <item type="cascade" label="more...">
      <menu>
        <item type="command" label="more items here" command="whatever"/>
      </menu>
    </item>
  </menu>

  <menu>
  Label1 :
    It was a cascade : commandName
    So here's a submenu : sub {}
    And the commands can have various formats : [\&codeRef, @args]
  Label_2 : theUnderscoreDoesKeybindings(); 
  </menu>
  
YAMLish is the easiest way to do this... the key is always a label, the value can be something to be interpreted
as subroutine, or cascade submenu.

=head1 script

It looks like this:

  <script>
  print "here is my perl script";
  </script>

and the other obvious option...

  <?  "print this to the screen" ?>  

No brainer.

Everything else is interpreted as markdown.

Menu should be at the top of the document... there may some way to add to it later.

Notebook and pages should be separated before any markdown interpretation.

The bits of other stuff should be processed as we go through the markdown... which needs to happen using the search/
replace function of the Tk::Text.


We can't really use YAML modules for parsing because they put the data into hashes, losing the order!  Very annoying.


=cut

use strict;


use Tk;
use Tk::ROText;

undef $/;
my $data = <DATA>;



my %definitions = {
  window => sub {
    # this (window) is the name of a tag, and we'll be passed the bits and bobs required
    my ($attrs, $content, $parent) = @_; # in this case we disregard "main"
    $parent = new MainWindow(attr2opts($attrs));
    parser($content,$parent);
  },
};
sub attr2opts {
  my $attrs = shift;
  return map {'-'.$_ => $attrs->[$_]} keys %$attrs;
}
sub parser {
  my $content = shift;
  my @elements = ();
  while($content){
    my ($tag,$attrs,$cont,$content) = parseXMLElement($content);
    push @elements, [$tag,$attrs,$cont];
  }
  return @elements;
}

use Data::Dumper;
print Dumper [parser($data)];


sub parseXMLElement {
  my ($content) = @_;
  $content =~ /(\s*<(\w+)([^>]*)>)/s || return ('',{},$content,'');
  my ($alltag,$tag,$attrs) = ($1,$2,$3);
  my %attrs = ();
  while($attrs =~ /\G\s*(\w+)(?:="([^"]+)"|'([^']+)'|=(\S+)|)/sgi){
    $attrs{$1} = $2.$3;
  }
  my $level = 1;
  my $endtag;
  my $length = length($alltag);
  $content = substr($content,$length);
  $length = 0;
  my $length2 = 0;
  while($content =~ m!(\G.*?)(<(/?)(\w+)([^>]*)(/?))>!gis){
    my ($inter, $all, $beginslash, $tagname, $attrs, $endslash) = ($1,$2,$3,$4,$5,$6);
    print map {"<> $_\n"} ($2,$3,$4,$5,$6);
    if($beginslash){ $level --; } # decrement if starting /
    elsif($endslash){ } # not change if ending /
    else { $level ++; } # increment if no /
    $endtag = $tagname;
    $length += length($inter);
    $length2 = $length + length($all) + 1;
    last if $level < 1;
    $length = $length2;
  }
  die "mismatching tags: $tag vs $endtag" unless $tag eq $endtag;
  return ($tag, \%attrs, substr($content,0,$length), substr($content,$length2));
}


sub dataToApp {
  my ($data) = @_; # it's a string
  my @data = split /(?!\\\s*)(?:\n|\r|\r\n)/, $data;
  my %parts = (menu=>[],page=>[],script=>[]);
  my $pattern = join('|', keys %parts);

  while (@data){
    my $line = shift @data;
    if($line =~ /^<($pattern)/){
      my $tag = $1;
      push @{$parts{$tag}}, $line;
      while(@data){
        my $innerline = shift @data;
        last if $innerline =~ qr!^</$tag!;
        push @{$parts{$tag}}, $line;
      }
    }
  }

  my $mw = new MainWindow;

  

  my $text = $mw->Scrolled('ROText',-scrollbars=>'se')->pack(-expand=>1, -fill=>'both');
  $text->menu(undef);
}

MainLoop;


__DATA__
<menu>
  <menuitem type="cascase">
    <menu>
    </menu>
  </menuitem>  
</menu>
<page>
#
</page>
