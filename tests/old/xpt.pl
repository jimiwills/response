package Tk::XPT;

use XML::Simple;
use Data::Dumper;


my $app = XMLin(join('',<DATA>),
  ForceArray =>1,

);

print Dumper $app;

=pod 

=head1 NAME

Tk::XPT - write perl/tk apps (or parts of them) in xml

=head1 DESCRIPTION



=head1 Rules...

The name of the root node is probably ignored.
The default is to take all options from the attributes.
For toplevels and frames, the default is to use child nodes
as the definitions for child widgets.
For other widgets, the child nodes with be used for options.
If the content is text, not nodes, the default behaviour varies
for each widget... but in general it is used as an option



Label => -text  
Button => -text
Optionmenu => -options (one item per line, label and value are colon separated)


Special nodes...

Grid - indicates that the contents are to be gridded.  Each successive child is
added to the next column.  
Br - special node of grid that resets column and increments row.
Balloon - uses a global balloon object to display help attached to the parent node
Button - text?? or code??

=cut

__DATA__
<xml>
<MainLoop/>
</xml>

