package Bio::MaxQuant::Evidence;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp qw(cluck);
use Text::CSV;
use IO::File;


=head1 NAME

Bio::MaxQuant::Evidence - The great new Bio::MaxQuant::Evidence!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# options that get filtered through for the CSV object
our @CSV_OPTS = qw/eol sep_char allow_whitespace blank_is_undef empty_is_undef quote_char
        allow_loose_quotes escape_char allow_loose_escapes binary types always_quote quote_space
        quote_null keep_meta_info verbatim auto_diag/; 

our %DEFAULT_OPTS = (
    sep_char = "\t", # default separation character for text::csv
    line_end_patterns => [    
        qr/.(\r\n)./,
        qr/.(\n\r)./, 
        qr/.(\n)./,
        qr/.(\r)./
    ],
    line_end_chunksize => 2**10, # 1 kb
    line_end_maxread => 2**20, # 1 Mb
    file => 'evidence.txt',
    id_name = 'id', 
    protein_groups_name = 'Protein Group IDs',
    ratio_name = 'Ratio H/L',
    expt_name = 'Experiment',
    expt_group_pattern = '.*',
);

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Bio::MaxQuant::Evidence;

    my $foo = Bio::MaxQuant::Evidence->new();
    ...

=head1 EXPORT OK

=item rebuildProteinGroups

Exported on request... rapid interface to reading evidence file and rebuilding proteinGroups 
with defined filters in place at the evidence level.

=item recalculateRatios

Exported on request... rapid interface to reading evidence file and reporting ratios with defined
filters in place at the evidence level.

=head1 METHODS

Most methods take %options that they'll pass to reinit() so sort out.  Most methods also return the object
itself, so you can chain the method calls... e.g.


    Bio::MaxQuant::Evidence->new($file,%options)
        ->rebuildProteinGroups->calculateRatios->outputRatios($fh)
        ->dieErrors;
        

=head2 new

Generates a new object.  Optional filename as first argument.  Other arguments passed in key/value pairs

e.g.

    Bio::MaxQuant::Evidence->new($file, %options);
    #   or
    Bio::MaxQuant::Evidence->new(file=>$file, %options);
    #   or
    Bio::MaxQuant::Evidence->new(%options, file=>$file);
    #   it really makes no difference
    #   although this would be wrong:
    Bio::MaxQuant::Evidence->new(%options, $file);
    
New will try to open a filehandle if you provided a parameter for that, using IO::File
    
Options are required for various other functions, but can all be defined in new, and will be used later.  
Or you can give them later.  

If you don't supply a filename, the filename 'evidence.txt' is taken as the default.


=cut

sub new {
	my $p = shift;              # proto
	my $c = ref($p)||$p;    # class name
	bless $o, $c;                 # bless
	return $o->reinit(@_);  # return object, calling reinit first
}

=head2 reinit

sets new options for the object (carrying any previously set), and performs any initialization necessary,
e.g. opening a new file handle.  Returns the object for convenient chaining of commands.

    $o->reinit($file);
    #   or
    $o->reinit(filter=>[Experiment=>qr/expt1/]);
    
Every method, including new, calls this function with whatever parameters you pass.

=cut

sub reinit {
	my ($o) = shift; # object in
	my %fileq = (); # new file??
	if(@_ % 2){ # odd number... assume first is filename
		%fileq = (file => shift @_); # now there's a file in fileq, and it's even
	} # @_ must now be even, cos we shifted if it was odd
    my %opts = (@_,%fileq); # (new) options and file ... this can never fail!
    
    # open handle on file... if file exists
	if($opts{file}){ # file is defined, so...
		$o->{fh} = IO::File($opts{file}, 'r') # new handle on it... read only!
            || return $o->error("Couldn't open $opts{file} for reading: $!"); # return obejct with error on fail
        $o->{headerrow} = []; # remove the headerrow... headerRow() will generate a new one
        $o->guessLineEnding(); # important!
        return $o if $o->{error}; # call this in every method after every call to another method ... returns object with error
        my $le = $o->{line_end}; # assuming guessLineEnding did it's job
        if($le ne $o->{eol}){ # if it's a different end of line
            $opts{eol} = $le; # put it in the options...
        }
	}
    
    # flag to reset csv if necessary:
    my $resetcsv = 0; # 0=no need 1=need to reset
    foreach(@CSV_OPTS){ # @CSV_OPTS is defined at the top of this file
        if(exists $opts{$_} && (! exists $o->{$_} || $opts{$_} ne $o->{$_}){ 
            # a csv option was defined...  and is different from previous
            $resetcsv = 1; # need to reset
            last; # no point checking the rest...
        }
    }
    
    # now merge with previous and defaults, overwriting...
    %$o = (%DEFAULT_OPTS,%$o, %opts);
    
    # now reset the csv object if necessary
    if($resetcsv){# need to reset
        $o->{csv} = Text::CSV->new(extractCSVoptions(%$o)) 
            || $o->error("couldn't create new Text::CSV: $!");
    }
    if($opts{file}){ # new file?
        $o->headerRow; # make sure header has been read!
        return $o if $o->{error}; # call this in every method after every call to another method
    }
    
    return $o; # always return the object
}

=head2 calculateRatios

Gets the (log) median ratio for each protein group in the file.  Filters are active, as are experiment 
name patterns.  Each filter comprises a column name and a regular expression.  For each row, if 
the value of the named column doesn't match then the row is skipped.  ALL the filters must match.
If you want ORs, either encode them in you pattern or email me and I'll add the feature.  

eg:

    filter => ["Modified Sequence" => qr/^[^W]$/] 
    # i.e. modified sequence must not contain tryptophan

Experiment group patterns match part of the experiment name (or whichever column you change expt_name to).
That match is use to key the ratios into different column for reporting.  E.g. the default is "Experiment"
and qr/.*/ which means that the whole value of the Experiment column is use (a normal report).  But
say your experiments were labelled A1, A2, A3, B1, B2, B3 ...etc, where the number represented a
replica number, and you wanted to combine replicates, then you could change the pattern to qr/[A-Z]+/
and only the letter would be use to fold the data together, thus ignoring the replicate numbers.

eg:

    # group by experiment name (default)
    expt_name => "Experiment", expt_group_pattern => qr/.*/
    
    # group by a 6-digit number in the raw file name (e.g. date)
    expt_name => "Raw File", expt_group_pattern => qr/\d{6}/
    
=cut

sub calculateRatios {
    my ($o,%opts) = @_; # object and options in
    $o->reinit(%opts) if %opts; # always reinit if there are options
    return $o if $o->{error}; # call this in every method after every call to another method
    
    ## TO DO:
    # incorporate support for filtered protein groups
    # incorporate support for altered protein groups
    # incorporate support for normalization
    
    
    # check column names....
    $o->checkColumns; # make sure all column names are OK
    return $o if $o->{error}; # call this in every method after every call to another method
    
    # grab the values we're gonna use from the options...
    #    my @checks = qw/expt_name protein_groups_name ratio_name id_name expt_group_pattern /;
    my $expt_name = $o->{expt_name};
    my $protein_groups_name = $o->{protein_groups_name};
    my $ratio_name = $o->{ratio_name};
    my $id_name = $o->{id_name};
    my $expt_group_pattern = $o->{expt_group_pattern};
    my @filters = @{$o->{filter}};
        
    # filehandle...
    my $fh = $o->{fh};
    # csv object
    my $csv = $o->{csv};
        
    # now get on with reading the file...
    my %proteinGroups = ();
    while(! eof($fh)){
        my $row = $csv->getline_hr ($fh);
        my $ok = 1;
        foreach my $f(@filters){
            my ($k,$v) = @$f;
            if($row->{$k} !~ /$v/){
                $ok = 0;
                last;
            }
        }
        next unless $ok;
        my $pgid = $row->{$protein_groups_name};
        next if $pgid =~ /;/;
        my $ratio = $row->{$ratio_name};
        next unless $ratio =~ /^[\d\.]+$/;
        my $id = $row->{$id_name};
        $proteinGroups{$pgid} = {} unless defined $proteinGroups{$pgid};
        $proteinGroups{$pgid}->{$id} = $ratio;
    }
    
    # now report...
    $o->{output_header} = [$protein_groups_name, $ratio_name, 'Count', $id_name.'s', $ratio_name.'s'];
    $o->{output_table} = [];
    foreach my $pgid(sort {$a <=> $b} keys %proteinGroups){
        my %ir = %{$proteinGroups{$pgid}};
        my @i = sort {$ir{$a} <=> $ir{$b}} keys %ir;
        my @r = map {$ir{$_}} @i;
        my $median = logmedian(@r);
        push @{$o->{output_table}}, [
            $pgid, $median,
            scalar(@i),
            join(';',@i),
            join(';',@r),
        ];
    }

    return $o; # always return the object
}

=head2 outputRatios(fh)

=cut

sub outputRatios {
    my ($o, $fh, %opts) = @_; # object and options in
    $o->reinit(%opts) if %opts; # always reinit if there are options
    return $o if $o->{error}; # call this in every method after every call to another method
    #
    # TODO:
    #    write the stored ratios out to $fh using CSV
    #    
    return $o; # always return the object
}


=head2 checkColumns

Checks the columns names used in the options can be found in the header row of the file.
Warns with a useful message if a column name is not found, and sets $o->{error}
Returns the object for chaining methods

=cut

sub checkColumns {
    my ($o,%opts) = @_; # object and options in
    $o->reinit(%opts) if %opts; # always reinit if there are options
    return $o if $o->{error}; # call this in every method after every call to another method
    my @checks = qw/expt_name protein_groups_name ratio_name id_name expt_group_pattern /;
    # and also check all the filters... we can fold them into a hash and just check each column once...
    my %col_check = (@{$o->{filters}}, map {$_=>0} @checks); # filers and named columns
    my %h = map {$_=>0} @{$o->{headerrow}}; # the header as a hash
    my $count = 0; # how many weren't found in the header
    foreach(keys %col_check){ # each name we'll be using...
        $count += $col_check{$_} = ! exists $h{$_}; # set col_check to 1 if not found, and increment count
    }
    # if any weren't found... return with a nice error
    $count && return $o->error("$count column names were not found: "
        . join("\t", map {$col_check{$_} ? "'$_'" : ()} keys %col_check)); 
    return $o; # always return the object
}


=head2 warnErrors / carpErrors / cluckErrors / dieErrors / croakErrors / confessErrors

Call one of these self explanatory items at the end of a chain.

warnErrors / carpErrors / cluckErrors all reset the error after being called.
dieErrors / croakErrors / confessErrors  don't, because they terminate execution!

e.g. 
    
    Bio::MaxQuant::Evidence->new($file,%options)
        ->rebuildProteinGroups->calculateRatios->outputRatios($fh)
        ->dieErrors;
        
        # Error: could not write to $fh # or whatever
        
None of the functions will run if an error is logged, but dieErrors, or whatever, will croak/die/warn
with that error.

=cut

# annoying:
sub warnErrors { my $o = shift; warn $o->{error} if $o->{error}; $o->{error}='';}
sub carpErrors { my $o = shift; carp $o->{error} if $o->{error}; $o->{error}='';}
sub cluckErrors { my $o = shift; cluck $o->{error} if $o->{error}; $o->{error}='';}

# terminal:
sub dieErrors { my $o = shift; die $o->{error} if $o->{error}; }
sub croakErrors { my $o = shift; croak $o->{error} if $o->{error}; }
sub confessErrors { my $o = shift; confess $o->{error} if $o->{error}; }


=head1 INTERNALLY USED METHODS

These methods do not take the %options because they do not call reinit() because they are called from reinit()

=head2 headerRow

Reads the header row if necessary ... returns the object.
Does NOT take any %options.
Called in reinit when a new file is defined, so you should never need to call this yourself.

=cut

sub headerRow {
    my $o = shift; # object ... no options here
    $o->{headerrow} = [] unless ref $o->{headerrow}; # set it unless already ok
    if(! @{$o->{headerrow}}){ # if empty, fill!
        $o->{fh}->seek(0,0) || return $o->error("couldn't seek on filehandle: $!"); # bof
        $o->{headerrow} = $o->{csv}->getline($o->{fh}) # readline from csv
            || return $o->error("couldn't getline from csv: $!"); # or err
        $o->{csv}->column_names($o->{headerrow}); # set line as column names
    }
    return $o; # always return the object
}


=item $o->guessLineEnding() 

I should probably be using a different module for this, but I couldn't find one.
Anyway, this takes the file handle and reads some bytes.  It looks for the following
patterns in this order...

    qr/.(\r\n)./
    qr/.(\n\r)./ # i'm pretty sure this shouldn't be used anywhere, but maybe
                # somebody makes a mistake sometimes?
    qr/.(\n)./
    qr/.(\r)./
    
The extra characeters ensure that we didn't miss the end of a pattern over a chunk boundary.
Whichever matches first is put into $o->{line_end} and $o is returned.
If none match, another read is done and appended.
File is read in 1kb chunks until something matches or eof is reached or 1Mb is reached (that's a big header!)
This can be changed in:

    line_end_patterns => [...]
    line_end_chunksize => 2048 # or whatever
    line_end_maxread => 2**30 # read a Gb headerrow!  (yeah right!)

Anyway, this is called in reinit() whenever a new file is given in the options, so you should never need to
call it yourself.  It takes no %options.

=cut

sub guessLineEnding {
    my $o = shift; #  no options!
    my $fh = $o->{fh}; # file handle (hopefully it's open!)
    my $match=0;  # match flag
    my $line_end = "\r\n"; # default line end
    my $fp = tell($fh); # remember where the file pointer is
    seek($fh,0,0); # go to file start
    my $buffer; # empty buffer
    my $size = 0; # buffer start size
    while(! $match){ # while no match found...
        $size += read($fh, $buffer, $o->{line_end_chunksize}, $size); # read chunk, with size offset, incr size, 
        foreach (@{$o_>{line_end_patterns}}){ # test each pattern
            if($buffer =~ /$_/){ # if it matches
                $match = 1; # set the flag
                $line_end = $1; #  remember the bit in parentheses
            }
        }
        last if eof($fh); # exit loop if end of file reached
        last if $match; # or if we found a match (this is redundant)
        last if $size > $o->{line_end_maxread}; # or if we reach the maximum buffer size
    }
    seek($fh,$fp,0); # put the file pointer back where it was!
    $o->{line_end} = $line_end; # set line end (even if only to the default)
    $match || return $o->error("no line end determined (falling back to CRLF)"); # err if no match
    return $o; # always return the object
}

=head2 error

defined that an error has happened...

    return $o->error($mesg); # returns $o
    
used internally to conveniently return $o and set error in the same statement (e.g. before an if or unless or after a || or &&)

=cut

sub error {
    my ($o,$mesg) = @_; # object, error message
    $o->{error} = $mesg; # set the error message
    return $o; # always return the object
}

=head1 FUNCTIONS

=item extractCSVoptions(%options) 

extracts from the given hash all of the options that are relevant to Text::CSV and returns them in a hashref.
used in reinit.

=cut

sub extractCSVoptions {
    # function, not method!
    my (%opts) = @_; # some options
    my %csvopts = (); # empty hash for those options relevant to Text::CSV
    foreach(@CSV_OPTS){ # defined at top of this file
        $csvopts{$_} = $opts{$_} if defined $opts{$_}; # set if defined
    }
    return \%csvopts; # return hash of those options relevant to Text::CSV
}

=item logmedian(values) 

takes a list of values and calculates the log median (averaging on log scale if even list given)

=cut

sub logmedian {
	return @_ % 2 ?
		$_[int @_/2] :
		exp((
			log($_[@_/2])
		+	log($_[@_/2 -1])
		)/2);
}


=head1 RELATED MODULES

Text::CSV IO::File

=head1 AUTHOR

Jimi Wills, C<< <jimi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-maxquant-evidence at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-MaxQuant-Evidence>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::MaxQuant::Evidence


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-MaxQuant-Evidence>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-MaxQuant-Evidence>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-MaxQuant-Evidence>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-MaxQuant-Evidence/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jimi Wills.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Bio::MaxQuant::Evidence
