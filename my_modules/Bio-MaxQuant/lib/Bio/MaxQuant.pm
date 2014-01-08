package Bio::MaxQuant;

use 5.010001;
use strict;
use warnings;
use Carp;
use DBI;
use IO::Dir;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::MaxQuant ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


sub new {
    my $p = shift;
    my $c = ref($p) || $p;
    my $o = {};
    bless $o, $c;
    return $o;
}



sub setCombinedFolder {
    my ($o,$dir) = @_;
    # creates a database handle
    my $dbh = DBI->connect('dbi:AnyData(RaiseError=>1):');
    $o->{dbh} = $dbh;
    my @tables = defined $o->{tables} ? @{$o->{tables}} : ();
    if(! @tables){
        my $d = IO::Dir->new($dir);
        if (defined $d) {
            while (defined($_ = $d->read)) {
                push @tables, $_;
            }
        }
        else {
            croak "Could not read directory $dir: $!";
        }
    }
    foreach my $tn(@tables){
        # specifies the table, format, and file holding the data
        my $name = $tn;
        $name =~ s/\.txt$//i;
        print "<<< $name >>>\n";
        print STDERR "<<< $name >>>\n";
        $dbh->func( $name, 'Tab', $dir.'/'.$tn, 'ad_catalog');
        # through 8 use DBI and SQL to access data in the file
        my $sth = $dbh->prepare("SELECT id FROM $name");
        $sth->execute();
        print "<Results from $name:";
        while (my $row = $sth->fetch) {
            if(ref($row)){
                print ' '.join(' ',@$row);
            }
            else {
                print STDERR "Error: $row\n";
            }
        }
        print " ... results from $name>\n";
    }
}

# Preloaded methods go here.



package main;

my $mq = new Bio::MaxQuant;
$mq->setCombinedFolder("/home/jbwills/data/024.Quantitation-II/XSQ/20110420");


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bio::MaxQuant - Read MaxQuant text output easily

=head1 SYNOPSIS

  use Bio::MaxQuant;
  my $mq = new MaxQuant();
  $mq->setCombinedFolder($path);
  my $prot = $mq->nextProteinGroup();
  my @oPeps = $prot->peptides();
  # etc

=head1 DESCRIPTION

This module acceses MaxQuant output tables using DBD::AnyData... the work of joining the tables is done.

=head2 EXPORT

None by default... this is object oriented.



=head1 SEE ALSO

DBD::AnyData

The MaxQuant website and Group: <lt>www.maxquant.org<gt> <lt>groups.google.com/group/maxquant-list<gt>

=head1 AUTHOR

Jimi-Carlo Bukowski-Wills, <lt>jimi@pause.cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jimi-Carlo Bukowski-Wills

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
