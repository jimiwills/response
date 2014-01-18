package Bio::MaxQuant::Evidence::Statistics;

use 5.006;
use strict;
use warnings;

use Text::CSV;
use Carp;

=head1 NAME

Bio::MaxQuant::Evidence::Statistics - Additional statistics on your SILAC evidence

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Read/convert your evidence file to a more rapidly processable format,
and perform various operations and statistics across/between multiple
experiments.  Supports multidimensional experiments with replicate
analyses.


    use Bio::MaxQuant::Evidence::Statistics;

    my $foo = Bio::MaxQuant::Evidence::Statistics->new();
    
    # get the essential data from an evidence file
    $foo->parseEssentials(filename=>$evidencePath);

    # store the essentials for later
	$foo->writeEssentials(filename=>$essentialsPath);

	# laod previously stored essentials
	$foo->readEssentials(filename=>$essentialsPath);


=head1 SUBROUTINES/METHODS

=head2 new

Create a new object:

	my $foo = Bio::MaxQuant::Evidence::Statistics->new();

=cut

sub new {
    my $p = shift;
    my $c = ref($p) || $p;
    my %defaults = (
        separator => "\t",
        essential_column_names => {
            'id'                => 1,
            'Protein group IDs' => 1,
            'Modified'          => 1,
            'Leading Proteins'  => 1,
            'Experiment'        => 1,
            'PEP'               => 1,
            'Ratio H/L'         => 1,
            'Intensity H'       => 1,
            'Intensity L'       => 1,
            'Contaminant'       => 1,
            'Reverse'           => 1,
        },
        key_column_name        => 'id',
        experiment_column_name => 'Experiment',
    );
    my %options = (%defaults, @_);
    my $o = {defaults=>%options};
    bless $o, $c;
    return $o;
}

=head2 parseEssentials(%options)

Reads the essential data from an evidence file.  Evidence files
for large analyses can be very big and take a long time to process,
to we only read what's necessary, and can save this for convenience
and speed too, using writeEssentials().

The data are stored by Protein group IDs, i.e. one entry per protein
group.  Other data stored here are:

=over

=item id

=item Protein group IDs

=item Modified  -- is this actually the right name??

=item Leading Proteins

=item Experiment

=item PEP

=item Ratio H/L

=item Intensity H

=item Intensity L

=item Contaminant

=item Reverse

=back

The column names used for storage are defined in the default option
essential_column_names, and can be changed when you call new, or when you call
parseEssentials.  The option is a hash of column names whose values
detmerine whether the column is kept by their truthness... e.g.

    $o->parseEssentials(essential_column_names=>(
        'id'  => 1, # kept
        'PEP' => 0, # discarded
        #foo  => ?, # discarded
    ));

If a column doesn't exist, it does not complain!

The method takes a hash of options.

options:

=over

=item filename - path of the file to process

=item separator - passed to Text::CSV (default is tab)

=item key_column_name - change the column keyed on (default is id)

=item experiment_column_name - change the column the data are split on

=back

=cut

sub parseEssentials {
    my $o = shift;
    my %defaults = %{$o->{defaults}};
    my %options = (%defaults, @_);
    my $io = IO::File($options{filename}, 'r');
    my $csv = Text::CSV->new();
    # read the column names, just like in the pod...
    $csv->column_names ($csv->getline ($io));
    # now getline_hr will give us hashrefs :-)
    # we just need to know which to keep...
    my %k = %{$o->{essential_column_names}};
    my $i = $o->{key_column_name};
    my $e = $o->{experiment_column_name};
    my %data = ();
    my %ids = ();
    
    while(! eof($io)){
        my $hr = $csv->getline_hr($io);
        my %h = map {
                exists $k{$_} && $k{$_} # exists and true
                 ? ($_=>$hr->{$_})      # key => value
                 : ()                   # empty
            } keys %$hr;
        my $key = $hr->{$i};
        my $expt = $hr -> {$e};
        # store it...
        $ids{$key} = 1; # keep track of what we've got
        # store stuff by expt, then id, then column
        $data{$expt} = {} unless exists $data{$expt};
        $data{$expt}->{$key} = map {
                exists $data{$expt}->{$key}->{$_}
                 ? ($data{$expt}->{$key}->{$_} .';'.$h{$_})
                 : ($_=>$h{$_})
            }
            keys %h;
    }
    $o->{data} = \%data;
    $o->{ids} = \%ids;
}

=head1 AUTHOR

jimi, C<< <j at 0na.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-maxquant-evidence-statistics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-MaxQuant-Evidence-Statistics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::MaxQuant::Evidence::Statistics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-MaxQuant-Evidence-Statistics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-MaxQuant-Evidence-Statistics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-MaxQuant-Evidence-Statistics>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-MaxQuant-Evidence-Statistics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 jimi.

This program is released under the following license: artistic2


=cut

1; # End of Bio::MaxQuant::Evidence::Statistics
