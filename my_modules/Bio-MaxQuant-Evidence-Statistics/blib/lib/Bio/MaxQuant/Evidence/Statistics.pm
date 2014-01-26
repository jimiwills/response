package Bio::MaxQuant::Evidence::Statistics;

use 5.006;
use strict;
use warnings;

use Text::CSV;
use Carp;
use Storable;

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
            'Protein group IDs' => 1,
            'Modified'          => 1,
            'Leading Proteins'  => 1,
            'PEP'               => 1,
            'Ratio H/L'         => 1,
            'Intensity H'       => 1,
            'Intensity L'       => 1,
            'Contaminant'       => 1,
            'Reverse'           => 1,
        },
        list_column_names      => {
            'Modified'          => 1,
            'PEP'               => 1,
            'Ratio H/L'         => 1,
            'Intensity H'       => 1,
            'Intensity L'       => 1,
        },
        key_column_name        => 'id',
        experiment_column_name => 'Experiment',
        csv_options            => {sep_char=>"\t"},
    );
    my %options = (%defaults, @_);
    my $o = {defaults=>\%options};
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

=item list_column_names - change the columns stored as lists

=back

=head3 list_column_names

Some columns are the same across all the evidence in a protein group, 
eg, the id is obviously the same, Contaminant and Reverse, Protein IDs, 
and so on.  The default, therefore, is to overwrite the column with
the value seen in an evidence.  BUT, some columns have a different value
in each evidence, e.g. Ratio H/L or PEP.  Whatever columns are given in 
list_column_names, which true values, will be appended as lists, so in the
final data, there will be one row per protein and any column bearing multiple
evidences for that protein will be a list.

If that makes no sense, write to me and I'll try to change it.

=cut

sub parseEssentials {
    my $o = shift;
    my %defaults = %{$o->{defaults}};
    my %options = (%defaults, @_);
    my $io = IO::File->new($options{filename}, 'r');
    my $csv = Text::CSV->new($options{csv_options});
    # head the column names, just like in the pod...
    $csv->column_names ($csv->getline ($io));
    # now getline_hr will give us hashrefs :-)
    # we just need to know which to keep...
    my %k = %{$options{essential_column_names}};
    my $i = $options{key_column_name};
    my $e = $options{experiment_column_name};
    my %l = %{$options{list_column_names}};
    my %data = ();
    my @ids = ();
    my @sharedids = ();
    my @uniqueids = ();
    
    while(! eof($io)){
        my $hr = $csv->getline_hr($io);
        my %h = map {
                exists $k{$_} && $k{$_} # exists and true
                 ? ($_=>$hr->{$_})      # key => value
                 : ()                   # empty
            } keys %$hr;
        my $key = $hr->{$i};
        my $expt = $hr->{$e};
        # store it...
        push @ids, $key; # keep track of what we've got
        # store stuff by expt, then id, then column
        $data{$expt} = {} unless exists $data{$expt};
        $data{$expt}->{$key} = { # set up this expt/key... unless it exists
            map {
                exists $l{$_} && $l{$_} 
                    ? ($_ => []) # it's an array
                    : ($_ => '') # it's a scalar
            } keys %h
        } unless exists $data{$expt}->{$key};
        # add the data...
        foreach (keys %h){ # each column
            if(exists $l{$_} && $l{$_}){ # is it a list column?
                push @{$data{$expt}->{$key}->{$_}}, $h{$_}; # push it
            }
            else {
                $data{$expt}->{$key}->{$_} = $h{$_}; # set it
            }
        }
        if($data{$expt}->{$key}->{'Protein group IDs'} =~ /;/){
            push @sharedids, $key;
        }
        else {
            push @uniqueids, $key;
        }
    }
    $o->{data} = \%data;
    $o->{ids} = [sort {$a <=> $b} @ids];
    $o->{sharedids} = [sort {$a <=> $b} @sharedids];
    $o->{uniqueids} = [sort {$a <=> $b} @uniqueids];
}

=head2 experiments

Returns a list of the experiments in the data.

=cut

sub experiments {
    my $o = shift;
    my $data = $o->{data};
    return  keys %$data;
}

=head2 ids 

Returns a list of evidence ids in the data.

=cut

sub ids {
    return @{shift()->{ids}};
}

=head2 sharedIds 

Returns a list containing the ids of those evidences shared between protein groups.

=cut

sub sharedIds {
    return @{shift()->{sharedids}};
}

=head2 uniqueIds 

Returns a list containing the ids of those evidences unique to one protein group.

=cut

sub uniqueIds {
    return @{shift()->{uniqueids}};
}

=head2 saveEssentials(%options)

Save the essential data (quicker to read again in future)

=cut

sub saveEssentials {
    my $o = shift;
    my %defaults = %{$o->{defaults}};
    my %options = (%defaults, @_);
    # here we want to save everything
    store $o, $options{filename};
}

=head2 loadEssentials

Load up previously saved essentials

=cut

sub loadEssentials {
    my $o = shift;
    my %defaults = %{$o->{defaults}};
    my %options = (%defaults, @_);
    my $p = retrieve($options{filename});
    %$o = %$p;
    return $o;
}


=head2 extractColumnValues

=cut

sub extractColumnValues {
    my ($o, %options) = @_;
    # options: 
    my %defaults = (
        column      => 'id', # which column to collect
        experiment  => '',   # only extract this expt (all if false)
        'split'     => 1,    # true = split cell on ; before adding to results
        'nodup'     => 1,    # true = remove duplicates
    );
    %options = (%defaults, %options);
    my $data = $o->{data};
    my $results = $options{nodup} ? {} : [];
    my @expts = $options{experiment} ? ($options{experiment}) : (keys %$data);
    foreach my $e(@expts){
        foreach my $k(keys %{$data->{$e}}){
            my $value = $data->{$e}->{$k}->{$options{column}};
            if(ref($value) eq ''){
                $value = [split /;/, $value];
            }
            my @values = $options{'split'} ? (@$value) : (join(';',@$value));
            foreach (@values){
                if($options{nodup}){
                    $results->{$_} = 1;
                }
                else {
                    push @$results, $_;
                }
            }
        }
    }
    return $options{nodup} ? (keys %$results) : (@$results);
}

=head2 proteinCount

=cut

sub proteinCount {
    my @proteins = shift()->getLeadingProteins();
    return scalar @proteins;
}

=head2 getProteinGroupIds

=cut

sub getProteinGroupIds {
    return sort shift()->extractColumnValues(column=>'Protein group IDs');
}

=head2 getLeadingProteins

=cut

sub getLeadingProteins {
    return sort shift()->extractColumnValues(column=>'Leading Proteins');
}

=head2 logRatios

Logs ratios (base 2) throughout the dataset, and sets a flag so it can't get logged again.

Treatment of "special values": empty string, <= 0, NaN, and any other non-number are removed
from the data!

=cut

sub logRatios {
    my $o = shift;
    return 0 if $o->{logged};
    $o->{logged} = 1;
    my $data = $o->{data};
    foreach my $exptname(keys %$data){
        my $experiment = $data->{$exptname};
        foreach my $proteinGroupId(keys %$experiment){
            my $proteinGroup = $experiment->{$proteinGroupId};
            my $ratios = $proteinGroup->{'Ratio H/L'};
            my @newRatios = ();
            foreach (0..$#$ratios){
                $ratios->[$_] = $ratios->[$_] =~ /^\d+\.?\d*$/
                    ? log($ratios->[$_])/log(2)
                    : '';
            }
        }
    }
    return 1;
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
