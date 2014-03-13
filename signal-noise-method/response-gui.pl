#!/usr/bin/perl

# response-gui.pl

use strict;
use warnings;
use utf8;
use Carp;
use Data::Dumper;
use Tk;
use Statistics::Reproducibility;
use Bio::MaxQuant::ProteinGroups::Response;
use Bio::MaxQuant::Evidence::Statistics;
use Tk::DirSelect;
use Tk::TixGrid;
use Tk::SplitFrame;
use Tk::Pane;
use Tk::Panel;
use Tk::DialogBox;
use Tk::ItemStyle;
use Tk::Font;
use Tk::ProgressBar;
use File::Basename;
use File::HomeDir;
use Config::Simple;
use Tk::BrowseEntry;

$app::top = MainWindow->new();

%App::Config = ();
$App::Config2{'files_proteinGroupsPath'} = '';
$App::Config2{'files_annotationsPath'} = '';
$App::Config2{'files_outputPath'} = '';

%app::selection_controls = ();
%app::columnIndex = ();
$app::filebuttons_row = 0;

$app::H = $app::W = 0;

%app::sortables = (
	'Filter' => 0,
	'Cells' => 1,
	'Conditions' => 2,
	'Condition Responses' => 3,
	'Differential Responses' => 4,
	'Data Type' => 10,
	'Processing Stage' => 11,
	'Annotations' => 20,

	'normalized' => 31,
	'medians' => 32,
	'spread' => 33,
	'DistanceToRegressionLine' => 33.5,
	'ErrorPvalue' => 34,
	'SpreadPvalue' => 35,
	'SpreadOverErrorPvalue' => 36,
	'ErrorOverSpreadPvalue' => 37,

	'source' => 41,
	'subtractMedian' => 42,
	'deDiagonalize' => 43,
	'rotateToRegressionLine' => 44,
);

sub App::Sortable {
	return $app::sortables{$_[0]} if exists $app::sortables{$_[0]};
	return 100;
}

$app::tixgrid_format = {
	x_margin => ['formatGrid'],
	y_margin => ['formatGrid'],
	s_margin => ['formatGrid'],
	main => ['formatGrid', -background=>'white'],
};

$app::filetypes = [
     ['Text Files',       ['.txt']],
     ['All Files',        '*',             ]
];

$app::side = $app::top->MyApp();
$app::side->ProcessControls()->grid(-sticky=>'we');
$app::side->FileControls(2)->grid(-sticky=>'we');

$App::Config{'directory'} = File::HomeDir->my_home;
$app::columnfilter = '';

$app::cfgPath = $App::Config{'directory'}.'/response.cfg';
if(! -f $app::cfgPath || (stat $app::cfgPath)[7] == 0){
	my $io = IO::File->new($app::cfgPath, 'w') or die $!;
	print $io "config_create\tok\n";
	close $io;
}

tie %App::Config, "Config::Simple", $app::cfgPath;
 tied(%App::Config)->autosave(1);  


$App::Config{'directory'} = File::HomeDir->my_home unless exists $App::Config{'directory'} && $App::Config{'directory'};

$app::top->MainLoop;


sub app::resp {
	$app::resp = Bio::MaxQuant::ProteinGroups::Response->new(
		filepath => $App::Config2{'files_proteinGroupsPath'},
		resultsfile => $App::Config2{'files_outputPath'},
	);

	$app::side->RefreshColumnFilters();
	App::GenerateColumnFilter();
}

sub App::BrowseCmd {
	($app::x,$app::y) = @_;
	return unless $app::x < $app::W && $app::y < $app::H;
	$app::gridmenu->post($app::tixgrid->pointerx,$app::tixgrid->pointery);
}

sub App::FixPanel {
	my $p = shift;
	my $c = $p->{check};
	$c->configure(-indicatoron=>0, -selectcolor=>$c->cget('-background'));
}

sub Tk::GridMenu {
	my $f = shift;
	my $m = $app::gridmenu = $f->Menu(-type=>'normal',-tearoff=>0);
	$m->add('command',-label=>'');
	$m->configure(-postcommand=>sub {
		my $text = $app::tixgrid->entrycget($app::x,$app::y,'-text');
		$m->entryconfigure(0, -label=>$text);
	});
	$m->add('separator');
	$m->add('command',-label=>'Edit',-command=>sub {
		my $v = $app::tixgrid->Ask(
			"Edit Cell",
			"Edit Cell ($app::x,$app::y)...",
			$app::tixgrid->entrycget($app::x, $app::y, '-text')
		);
		$app::tixgrid->entryconfigure($app::x, $app::y, -text=>$v)
			if $v;
	});
	$m->add('command',-label=>'row stuff here (eg select, annotate)');
	$m->add('separator');
	$m->add('command',-label=>'Column Width',-command=>sub {
		my %size = split /\s/, $app::tixgrid->sizeColumn($app::x);
		my $r = $app::tixgrid->Ask('Column Width',
			'Column width can be "default", "auto" or a positive integer',$size{-size});
		return unless $r;
		$app::tixgrid->sizeColumn($app::x, -size=>$r);
	});
	$m->add('separator');

	$m->add('command',-label=>'export this view',-command=>sub {
		my $fn = $m->getSaveFile(
			-title=>'Export...',
			-defaultextension => '.txt',
			-initialdir => $App::Config{'directory'},
			-filetypes => $app::filetypes,
		);
		return unless $fn;
		App::SetDirectory($fn);
		my $io = IO::File->new($fn,'w') or $m->messageBox(-title=>'Error', -message=>$!);
		foreach my $x(0..$app::W-1){
			my @parts = map {$app::tixgrid->entrycget($x, $_, '-text')} (0..3);
			my $head = join('/', map {$_ ? $_ : ()} @parts);
			print $io "\t" if $x;
			print $io $head;
		}
		print $io "\n";


		foreach my $y(4..$app::H-1){
			foreach my $x(0..$app::W-1){
				print $io "\t" if $x;
				print $io $app::tixgrid->entrycget($x, $y, '-text');
			}
			print $io "\n";
		}
		close($io);
	});
}

sub App::SetDirectory {
	my $fn = shift;
	return unless $fn;
	$App::Config{'directory'} = dirname($fn);
}

sub Tk::Ask {
	my ($f,$t,$m,$v) = @_;
	my $db = $f->DialogBox(-title=>$t,-buttons=>[qw/OK Cancel/]);
	$db->add('Label',-text=>$m)->pack;
	$db->add('Entry',-textvariable=>\$v)->pack;
	return if $db->Show eq 'Cancel';
	return $v;
}

sub Tk::RefreshColumnFilters {
	my $f = shift;
	foreach(keys %app::selection_controls){
		$app::selection_controls{$_}->destroy;
		delete $app::selection_controls{$_};
	}

	App::CollectSelectionOptions();

	my $ff = $f->Panel(-text=>'Filter')->grid(-sticky=>'we');
	App::FixPanel($ff);
	$ff->Label(-text=>"Use the checkboxes below to modify\nthe filter, or do it manually:")->pack;

	my $bef = $ff->Frame->pack(-expand=>1,-fill=>'x');
	$bef->Label(-text=>'Col')->pack(-side=>'left');
	$app::columnFilterBrowser = $bef->BrowseEntry(-variable=>\$app::columnfilter)->pack(-expand=>1,-fill=>'x',-side=>'left');
	$bef->Button(-text=>'+',-command=>\&App::AddColumnFilter, -padx=>0)->pack(-side=>'left');
	$bef->Button(-text=>'-',-command=>\&App::DeleteColumnFilter, -padx=>0)->pack(-side=>'left');
	
	my $bef2 = $ff->Frame->pack(-expand=>1,-fill=>'x');
	$bef2->Label(-text=>'Exp')->pack(-side=>'left');
	$app::experimentFilterBrowser = $bef2->BrowseEntry(-variable=>\$app::experimentfilter)->pack(-expand=>1,-fill=>'x',-side=>'left');
	$bef2->Button(-text=>'+',-command=>\&App::AddExperimentFilter, -padx=>0)->pack(-side=>'left');
	$bef2->Button(-text=>'-',-command=>\&App::DeleteExperimentFilter, -padx=>0)->pack(-side=>'left');
	
	my $bef3 = $ff->Frame->pack(-expand=>1,-fill=>'x');
	$bef3->Label(-text=>'Row')->pack(-side=>'left');
	$app::rowFilterBrowser = $bef3->BrowseEntry(-variable=>\$app::rowfilter)->pack(-expand=>1,-fill=>'x',-side=>'left');
	$bef3->Button(-text=>'+',-command=>\&App::AddRowFilter, -padx=>0)->pack(-side=>'left');
	$bef3->Button(-text=>'-',-command=>\&App::DeleteRowFilter, -padx=>0)->pack(-side=>'left');

	App::LoadExperimentFilters();
	App::LoadColumnFilters();
	App::LoadRowFilters();

	my $fff = $ff->Frame()->pack(-expand=>1,-fill=>'x');
	$fff->Checkbutton(-text=>"include\nreplicates",-variable=>\$app::show_replicates,-command=>\&App::GenerateColumnFilter)->pack(-expand=>1,-fill=>'x',-side=>'left');
	$fff->Checkbutton(-text=>"stats\nsummary",-variable=>\$app::show_stats,-command=>\&App::GenerateColumnFilter)->pack(-expand=>1,-fill=>'x',-side=>'left');
	$fff->Checkbutton(-text=>"flip\nview",-variable=>\$app::flip_view,-command=>\&App::GenerateColumnFilter)->pack(-expand=>1,-fill=>'x',-side=>'left');

	$fff->Button(-text=>'Apply Filter',-command=>\&App::ApplyFilter)->pack(-expand=>1,-fill=>'x',-side=>'left');

	$app::selection_controls{ffpanel} = $ff;

	foreach my $title( sort {App::Sortable($a) <=> App::Sortable($b)} keys %app::selectionFlags){

		$app::selection_controls{$title} = $f->SelectColumns($title);
		$app::selection_controls{$title}->grid(-sticky=>'we');

	}

 	$app::selection_controls{pg} = 
	 	$f->PGSelect();
	 $app::selection_controls{pg}->grid(-sticky=>'we');


}

sub App::LoadFilters {
	my ($name,$be) = @_;
	return unless $App::Config{$name."filter_count"};
	foreach my $i(0..$App::Config{$name."filter_count"}-1){
		$be->insert('end',$App::Config{$name."filter$i"});
	}
}

sub App::AddFilter {
	my ($name,$be,$f) = @_;
	my $sl = $be->Subwidget('slistbox');
	foreach (0..$sl->index('end')-1){
		my $v = $sl->get($_);
		return if $v eq $f;
	}
	$be->insert('end',$f);
	my $i = $App::Config{$name."filter_count"} || 0;
	$App::Config{$name."filter$i"} = $f;
	$App::Config{$name."filter_count"} ++;
}
sub App::DeleteFilter {
	my ($name,$be,$f) = @_;
	my $sl = $be->Subwidget('slistbox');
	$App::Config{$name."filter_count"} --;
	foreach my $i(0..$App::Config{$name."filter_count"}){
		if($App::Config{$name."filter$i"} eq $f){
			delete $App::Config{$name."filter$i"};
		}
	}
	foreach (0..$sl->index('end')-1){
		my $v = $sl->get($_);
		return $be->delete($_) if $v eq $f;
	}
}

sub App::LoadColumnFilters {
	return App::LoadFilters('column',$app::columnFilterBrowser);
}
sub App::AddColumnFilter {
	return App::AddFilter('column',$app::columnFilterBrowser, $app::columnfilter);
}
sub App::DeleteColumnFilter {
	App::DeleteFilter('column',$app::columnFilterBrowser, $app::columnfilter);
}

sub App::LoadRowFilters {
	return App::LoadFilters('row',$app::rowFilterBrowser);
}
sub App::AddRowFilter {
	return App::AddFilter('row',$app::rowFilterBrowser, $app::rowfilter);
}
sub App::DeleteRowFilter {
	App::DeleteFilter('row',$app::rowFilterBrowser, $app::rowfilter);
}

sub App::LoadExperimentFilters {
	return App::LoadFilters('experiment',$app::experimentFilterBrowser);
}
sub App::AddExperimentFilter {
	return App::AddFilter('experiment',$app::experimentFilterBrowser, $app::experimentfilter);
}
sub App::DeleteExperimentFilter {
	App::DeleteFilter('experiment',$app::experimentFilterBrowser, $app::experimentfilter);
}

sub App::Stats {
	my $F = shift;
	App::EmptyGrid();

	my $nextrow = 3;
	my $nextcol = 1;

	my %indices = ();

	foreach my $key(sort keys %app::columnIndex){
		next unless $key =~ /$F/;
		$key =~ m!/s\:([^/]+)/!; my $s = $1;
		$key =~ m!/d\:([^/]+)/!; my $d = $1;
		$key =~ m!/k\:([^/]+)/!; my $k = $1;
		$key =~ m!/t\:([^/]+)/!; my $t = $1;

		my $colname = "/$s/$d/$k/";
		my $rowname = "/$t/";

		if(! exists $indices{$colname}){
			$indices{$colname} = $nextcol++ ;
			my @cn = ($s,$d,$k);
			foreach my $y(0..2){
				my $x = $indices{$colname};
				my $i = $y;
				($x,$y) = ($y,$x) if $app::flip_view;
				$app::tixgridsets{"$x $y"} = 1;
				$app::tixgrid->set($x,$y,-text=>$cn[$i],
					-style=>$app::topmarginstyle);
				($x,$y) = ($y,$x) if $app::flip_view;
			}
		}
 
		if(! exists $indices{$rowname}){
			$indices{$rowname} = $nextrow++ ;
			my ($x,$y) = (0, $indices{$rowname});
			($x,$y) = ($y,$x) if $app::flip_view;
			$app::tixgridsets{"$x $y"} = 1;
			$app::tixgrid->set($x,$y,-text=>$t,
					-style=>$app::leftmarginstyle);
			($x,$y) = ($y,$x) if $app::flip_view;
		}

		my $value = $app::columnIndex{$key}->[0];
		my ($x,$y) = ($indices{$colname},$indices{$rowname});
		($x,$y) = ($y,$x) if $app::flip_view;
		$app::tixgridsets{"$x $y"} = 1;
		$app::tixgrid->set($x,$y,-text=>$value,
				-style=>$app::mainstyle);
		($x,$y) = ($y,$x) if $app::flip_view;
	}
	$app::W = $nextcol;
	$app::H = $nextrow;
	($app::W,$app::H) = ($app::H,$app::W) if $app::flip_view;



	App::TixGridFix();
}

sub Tk::PGSelect {
	my $f = shift;
	my $mw = $f->Panel(-text=>'Annotations');
	App::FixPanel($mw);
	my $row = 0;
	my $col = 0;
	foreach(@app::proteinGroupsHead){
		$mw->Checkbutton(-text=>$_,-variable=>\$app::selectionFlags{PG}->{$_},
			-command=>\&App::GenerateColumnFilter)
			->grid( -column=>$col, -row=>++$row, -sticky=>'w')
	}
	$row--;
	$mw->Button(-text=>'Apply', -command=>\&App::ApplyFilter)
		->grid(-sticky=>'e', -column=>++$col, -row=>$row, -rowspan=>2)
		unless $row < 0;
	return $mw;
}

sub App::ParseFilter {
	#print "\n $app::columnfilter \n $app::experimentfilter \n\n";

	my ($cf,$ef) = ($app::columnfilter , $app::experimentfilter);
	$cf =~ s!^[^/]+/!!g;
	$ef =~ s!^[^/]+/!!g;

	my @parts = split /\s+/, "$cf $ef";

	$app::show_replicates = 0;
	$app::show_stats = 0;
	$app::flip_view = 0;

	my %checks = ();

	my %pattern = ();
	foreach my $part(@parts){
		next unless $part;
		if($part eq 'replicates' || $part eq 'reps'){
			$app::show_replicates = 1;
		}
		elsif($part eq 'stats' || $part eq 'statistics'){
			$app::show_stats = 1;
		}
		elsif($part eq 'flip'){
			$app::flip_view = 1;
		}
		else {
			my ($key,$values) = split /\:/, $part;
			$pattern{$key} = $values;
			foreach(split /\|/, $values){
				$checks{"$key $_"} = 1;
			}
		}
	}


	my %titles = (
		'Data Type'   				 => 'data',
		'Processing Stage' 			 => 'procs',
		'Cells' 					 => 'cells',
		'Differential Responses' 	 => 'cells',
		'Conditions' 				 => 'conds',
		'Condition Responses' 		 => 'conds',
		'PG' 						 => 'pg',
	);

	foreach my $title(keys %app::selectionFlags){
		foreach my $name(keys %{$app::selectionFlags{$title}}){
			my $key = $titles{$title}.' '.$name;
			$app::selectionFlags{$title}->{$name} = $checks{$key} ? 1 : 0;
		}
	}




	my $nk = $app::show_replicates ? 'n' : 'k';
	my $n1 = $app::show_stats ? '1' : 'n';


	$pattern{procs} .= '|normalized|medians';
	$pattern{data} = $app::show_stats 
		? '[^/]+'  
		: $pattern{data}.'|data';




	
	my ($cells,$conds,$procs,$data,$pg) = map {
		if($pattern{$_} =~ /\|/){
			$pattern{$_} = "(?:$pattern{$_})";
		}
		$pattern{$_}
	} qw/cells conds procs data pg/;
	delete $pattern{$_} foreach qw/cells conds procs data pg/;
	foreach (keys %pattern){
		print STDERR "Warning: pattern key ``$_'' not recognised!\n";
	}



	my $qr = $nk eq 'n'
		? qr!$n1/s\:[^/]+/n\:$cells\.$conds/d\:$procs/k\:[^/]+/t\:$data/!
		: qr!$n1/s\:[^/]+/n\:[^/]+/d\:$procs/k\:$cells\.$conds/t\:$data/!;

	my $qr2 = qr!$pg!;

	return ($qr,$qr2);
}

sub App::EmptyGrid {
	for(my $y = $app::H-1; $y >= 0; $y--){
		for(my $x = $app::W-1; $x >= 0; $x--){
			$app::tixgrid->unset($x, $y);
		}
	}
	$app::W = $app::H = 0;
}

sub App::RowFilter {

	@app::filteredIndices = ();
	if(! defined $app::rowfilter || $app::rowfilter !~ /\S/){
		@app::filteredIndices = (0..$app::n-1);
		return;
	}

	my %CI = (%app::columnIndex, map {("annot/$_"=>$app::proteinGroups{$_})} keys %app::proteinGroups);

	my $COR = sub {
		my $c = shift;
		my @c = split /\*/,$c;
		my @list = ();
		foreach my $cn (keys %CI){
			push @list, $cn
				if Logic::AND(\@c,sub{return $_[1] =~ /\b$_[0]\b/;},$cn);
		}
		return \@list;
	};

	my %operators = (
		'<' => sub { Logic::OR( shift, sub{return $_[0] ne '' && $_[0] < $_[1]}, shift); },
		'<<' => sub { Logic::AND( shift, sub{return $_[0] ne '' && $_[0] < $_[1]}, shift); },
		'<=' => sub { Logic::OR( shift, sub{return $_[0] ne '' && $_[0] <= $_[1]}, shift); },
		'<<=' => sub { Logic::AND( shift, sub{return $_[0] ne '' && $_[0] <= $_[1]}, shift); },
		'>' => sub { Logic::OR( shift, sub{return $_[0] ne '' && $_[0] > $_[1]}, shift); },
		'>>' => sub { Logic::AND( shift, sub{return $_[0] ne '' && $_[0] > $_[1]}, shift); },
		'>=' => sub { Logic::OR( shift, sub{return $_[0] ne '' && $_[0] >= $_[1]}, shift); },
		'>>=' => sub { Logic::AND( shift, sub{return $_[0] ne '' && $_[0] >= $_[1]}, shift); },
		'=' => sub { Logic::OR( shift, sub{return $_[0] eq $_[1]}, shift); },
		'==' => sub { Logic::AND( shift, sub{return $_[0] eq $_[1]}, shift); },
		'!' => sub { Logic::OR( shift, sub{return $_[0] ne $_[1]}, shift); },
		'!!' => sub { Logic::AND( shift, sub{return $_[0] ne $_[1]}, shift); },
		'~' => sub { Logic::OR( shift, sub{return $_[0] =~ /$_[1]/ }, shift); },
		'~~' => sub { Logic::AND( shift, sub{return $_[0] =~ /$_[1]/ }, shift); },
		'#' => sub { Logic::OR( shift, sub{return $_[0] !~ /$_[1]/ }, shift); },
		'##' => sub { Logic::AND( shift, sub{return $_[0] !~ /$_[1]/ }, shift); },
	);
	my $patt = join('|',sort {length($b) <=> length($a)} keys %operators);
	my $qr = qr!$patt!;


	my $rf = $app::rowfilter;
	$rf =~ s!^[^/]+/!!g;
	$rf =~ s/(?:^\s+|\s+$)//g;

	my @OR = (
		map {
			[map {
						s/(?:^\s+|\s+$)//g;
						my @o = split (/($patt)/, $_, 3);
						$o[0] = &$COR($o[0]);
						\@o
				} 	split /\s+/
			]
		} 
		split /\s+OR\s+/, $rf
	);

	foreach my $i(0..$app::n-1){
		push @app::filteredIndices, $i 
	 	if Logic::OR(\@OR, sub {
					my ($and,$patt,$i) = @_;
					Logic::AND($and, sub {
							my ($statement,$patt,$i) = @_;
							my ($c,$o,$v) = @$statement;
							return &{$operators{$o}}([map {$CI{$_}->[$i]} @$c],$v);
						}, 
					$patt,$i);
				}, 
				$patt,$i);
	}
}

# returns true if any call to coderef supplying an item from $listref and the @args returns true
sub Logic::OR {
	my ($listref,$coderef,@args) = @_;
	foreach(@$listref){
		return 1 if &$coderef($_,@args);
	}
	return 0;
}
# returns false if any call to coderef supplying an item from $listref and the @args returns false
sub Logic::AND {
	my ($listref,$coderef,@args) = @_;
	foreach(@$listref){
		return 0 unless &$coderef($_,@args);
	}
	return 1;
}

sub App::ApplyFilter {

	App::RowFilter ();

	my ($F,$P) = App::ParseFilter ();

	if($app::show_stats){
		return App::Stats($F);
	}

	App::EmptyGrid();
	my $x = 0;
	my $leftMargin = 0;
	my $topMargin = 4;
	my $ymax = 0;


	foreach my $key(@app::proteinGroupsHead){
		next unless $key =~ /$P/;
		my $maxw = 0;
		my @col = @{$app::proteinGroups{$key}};
		my $y = 0;
		foreach ('','','',$key,@col[@app::filteredIndices]){
			($x,$y) = ($y,$x) if $app::flip_view;
			$app::tixgridsets{"$x $y"} = 1;
			$app::tixgrid->set($x,$y,-text=>$_,
				-style=>$y < $topMargin ? $app::topmarginstyle : $app::leftmarginstyle);
			($x,$y) = ($y,$x) if $app::flip_view;
			$y ++;
		}
		$leftMargin ++;

		$x++;
	}

	$app::tixgrid->configure(-leftmargin=>$app::flip_view ? $topMargin : $leftMargin);
	$app::tixgrid->configure(-topmargin=>$app::flip_view ? $leftMargin : $topMargin);

	foreach my $key(sort keys %app::columnIndex){
		next unless $key =~ /$F/;
		$key =~ m!/s\:([^/]+)/!; my $s = $1;
		$key =~ m!/d\:([^/]+)/!; my $d = $1;
		$key =~ m!/k\:([^/]+)/!; my $k = $1;
		$key =~ m!/t\:([^/]+)/!; my $t = $1;
		my @col = @{$app::columnIndex{$key}};
		my $y = 0;
		foreach ($s,$d,$k,$t,@col[@app::filteredIndices]){
			($x,$y) = ($y,$x) if $app::flip_view;
			$app::tixgridsets{"$x $y"} = 1;
			$app::tixgrid->set($x,$y,-text=>$_,
				-style=>$y < $topMargin ? $app::topmarginstyle : $app::mainstyle);
			($x,$y) = ($y,$x) if $app::flip_view;
			$y++;
		}
		$ymax = $y if $y > $ymax;

		$x++;
	}
	$app::W = $x;
	$app::H = $ymax;
	($app::H,$app::W) = ($app::W,$app::H) if $app::flip_view;
	App::TixGridFix();

}

sub App::TixGridFix {
	foreach my $x(0..$app::W-1){
		my $L = 0;
		foreach my $y(0..$app::H-1){
			if(exists $app::tixgridsets{"$x $y"}){
				delete $app::tixgridsets{"$x $y"}; # OK, it's already set
				my $l = length($app::tixgrid->entrycget($x,$y,'-text')) || 0;
				$L = $l if $l > $L;
			}
			else {
				$app::tixgrid->set($x,$y,-text=>'');
			}
		}
		$app::tixgrid->sizeColumn($x,-size=> $L > 20 ? 120 : 'auto');
	}
}

sub App::FileReadProgress {
	my $prog = $app::top->Toplevel(-title=>'Reading File');
	$prog->ProgressBar(
			-variable=>\$app::progress,-width=>40,-length=>300,
			-from=>0,-to=>100,-blocks=>20
		)->pack;
	return $prog;
}

sub App::ReadPGFile {
	my $prog = App::FileReadProgress();
	my $size = (stat $App::Config2{'files_annotationsPath'})[7];
	my $io = IO::File->new($App::Config2{'files_annotationsPath'},'r') or return;
	%app::proteinGroups = ();
	my $csv = Text::CSV->new({sep_char=>"\t"});
	my @h = @app::proteinGroupsHead = map {s/\s/_/g; $_} @{$csv->getline($io)};
	my %proteinGroupsSelected = ();
	@proteinGroupsSelected{@h} = map {0} @h;
	$proteinGroupsSelected{'Protein_names'} = 1 if exists $proteinGroupsSelected{'Protein_names'};
	$app::selectionFlags{PG} = \%proteinGroupsSelected;
	$csv->column_names(@h);
	@app::proteinGroups{@h} = map {[]} @h;
	my $i = 0;
	$app::resp->{median_exclude} = [];
	while(! eof $io){
		my $hr = $csv->getline_hr($io);
		foreach (keys %$hr){
			push @{$app::proteinGroups{$_}}, $hr->{$_};
		}
		if($hr->{Contaminant} || $hr->{Reverse}){
			push @{$app::resp->{median_exclude}}, $i;
		}
		$app::progress = int (100*tell($io)/$size);
		$prog->update;
		$i++;
	}
	close($io);	
	$prog->destroy;
	app::resp();
}

sub App::ReadResultsFile {
	my $prog = App::FileReadProgress();
	my $size = (stat $App::Config2{'files_outputPath'})[7];
	my $io = IO::File->new($App::Config2{'files_outputPath'},'r') or return;
	%app::columnIndex = ();
	my $csv = Text::CSV->new({sep_char=>"\t"});
	$app::n = 0;
	while(! eof $io){
		my $line = $csv->getline($io);
		next unless defined $line;
		my ($k, @v) = @$line;
		$app::columnIndex{$k} = \@v;
		$app::progress = int (100*tell($io)/$size);
		$prog->update;
		my $n = @v;
		$app::n = $n if $n > $app::n;
	}
	close($io);
	$prog->destroy;
	app::resp();
}

sub App::CollectSelectionOptions {
	my %conds = ();
	my %cells = ();
	my %condcomps = ();
	my %cellcomps = ();
	my %derivations = ();
	my %types = ();
	foreach (sort keys %app::columnIndex){
		next unless m!^n!;
		next unless m!/d\:([^/]+)/!;
		my $derived = $1;
		$derivations{$derived} or $derivations{$derived} = /\*/ ? 1 : 0;
		next unless m!/t\:([^/]+)/!;
		my $type = $1;
		$types{$type} or $types{$type} = /\*/ ? 1 : 0;
		next unless m!/s\:([^/]+)/!;
		my $section = $1;
		next unless $section =~ /replicate|differential/;
		next unless m!/n\:([^/]+)/!;
		my ($cell,$cond,$discardme) = $app::resp->parse_experiment_name($1.'.');
		if($section =~ /replicate/){
			$conds{$cond} = 1;
			$cells{$cell} = 1;
		}
		else {
			$condcomps{$cond} = 1;
			$cellcomps{$cell} = 1;
		}
	}
	%app::selectionFlags = ( 
		Cells => \%cells,
		Conditions => \%conds,
		'Differential Responses' => \%cellcomps,
		'Condition Responses' => \%condcomps,
		'Data Type' => \%types,
		'Processing Stage' => \%derivations, 
	);
}

sub App::GenerateColumnFilter {
	my (@cells,@conds,@resps,@diffs,@types,@procs,@pg);
	my %map = ('Cells'=>\@cells, 'Conditions'=>\@conds, 'Differential Responses'=>\@diffs, 
				'Condition Responses'=>\@resps,'Data Type'=>\@types, 'Processing Stage'=>\@procs,
				PG=>\@pg);
	foreach my $k(keys %map){
		@{$map{$k}} = map {$app::selectionFlags{$k}->{$_} ? $_ : ()}
				 keys %{$app::selectionFlags{$k}};
	}
	@cells = (@cells, @diffs);
	@conds = (@conds, @resps);

	my $cells = scalar(@cells) ? join('|', @cells) : '---';
	my $conds = scalar(@conds) ? join('|', @conds) : '---';
	my $types = scalar(@types) ? join('|', @types) : '---';
	my $procs = scalar(@procs) ? join('|', @procs) : '---';
	my $pg = scalar(@pg) ? join('|', @pg) : '---';

	my $showreps = $app::show_replicates ? 'reps ' : '';
	my $showstats = $app::show_stats ? 'stats ' : '';
	my $flipview = $app::flip_view ? 'flip ' : '';

	$app::experimentfilter = " cells:$cells conds:$conds ";

	$app::columnfilter = $flipview  . $showreps . $showstats
		. " data:$types procs:$procs pg:$pg";


}

# filter eg:  s:normalize|replicates d:

sub Tk::SelectColumns {
	my $f = shift;
	my $title = shift;
	my $mw = $f->Panel(-text=>$title);
	App::FixPanel($mw);
	my $col = 0;
	my $row = 0;
	foreach (sort {App::Sortable($a) <=> App::Sortable($b)} keys %{$app::selectionFlags{$title}}){
		next if $title eq 'Data Type' && /^data$/;
		next if $title eq 'Processing Stage' && /^medians$|^normalized$/;
		$mw->Checkbutton(-text=>$_,
			-variable=>\$app::selectionFlags{$title}->{$_},
			-command=>\&App::GenerateColumnFilter)
				->grid(-sticky=>'w', -column=>$col, -row=>++$row);
	}
	$row--;
	$mw->Button(-text=>'Apply', -command=>\&App::ApplyFilter)
		->grid(-sticky=>'e', -column=>++$col, -row=>$row, -rowspan=>2)
		unless $row < 0;
	return $mw;
}




sub Tk::MyApp {
	my $mw = shift;

	my $sf = $mw->SplitFrame()->pack(-expand=>1,-fill=>'both');

	my $f = $sf->Scrolled('Frame',-scrollbars=>'osoe')->pack(-fill=>'y',-side=>'left');

	$app::tixgrid = $sf->Scrolled(
		'TixGrid', -scrollbars=>'se',
		-leftmargin=>0,
		-topmargin=>0,
		-browsecmd=> \&App::BrowseCmd,
		-formatcmd => sub {
			my $name = shift;
			my ($method,@args) = @{$app::tixgrid_format->{$name}};
			$app::tixgrid->$method(@_,@args);
		},
		-itemtype => 'text',
		-selectunit=>'cell',
		-width=>10,
		-height=>20,
		-background=>'white',
	)->pack(-expand=>1,-fill=>'both',-side=>'left');

	$sf->configure('-sliderposition' => 350);

	$app::tixgrid->GridMenu();

	my $font_top = $app::tixgrid->Font(-family=>'Helvetica',-size=>10,-weight=>'bold',-slant=>'italic');
	my $font_left = $app::tixgrid->Font(-family=>'Helvetica',-size=>10,-slant=>'italic');
	$app::mainstyle = $app::tixgrid->ItemStyle('text',-stylename=>'mainstyle', -background=>'#efefef');
	$app::topmarginstyle = $app::tixgrid->ItemStyle('text',-stylename=>'topmarginstyle', -font=>$font_top);
	$app::leftmarginstyle = $app::tixgrid->ItemStyle('text',-stylename=>'leftmarginstyle', -font=>$font_left);

	return $f;
}





sub Tk::FileControls {
	my $f = shift;
	my $set = shift;
	my $mw;
	$mw = $f->Panel(-text=>'Input Files for Analysis');
	App::FixPanel($mw);
	$mw->FileButton(-label=>'ProteinGroups',-textvariable=>\$App::Config2{'files_proteinGroupsPath'},-type=>'getOpenFile',-callback=>'')->pack(-expand=>1,-fill=>'x');
	$mw->FileButton(-label=>'Output Results',-textvariable=>\$App::Config2{'files_outputPath'},-reloadbutton=>1,-type=>'getOpenFile',-callback=>\&App::ReadResultsFile)->pack(-expand=>1,-fill=>'x');
	$mw->FileButton(-label=>'Annotations',-textvariable=>\$App::Config2{'files_annotationsPath'},-reloadbutton=>1,-type=>'getOpenFile',-callback=>\&App::ReadPGFile)->pack(-expand=>1,-fill=>'x');
	return $mw;
}
sub Tk::ProcessControls {
	my $f = shift;
	my $mw = $f->Panel(-text=>'Processing');
	App::FixPanel($mw);

	my $bf = $mw->Frame->pack(-expand=>1,-fill=>'x');
	$bf->FileButton(-label=>'ProteinGroups',-textvariable=>\$App::Config2{'files_proteinGroupsPath'},-type=>'getOpenFile',-callback=>'')->pack(-expand=>1,-fill=>'x');
	$bf->FileButton(-label=>'Output Results',-textvariable=>\$App::Config2{'files_outputPath'},-type=>'getSaveFile',-callback=>\&app::resp)->pack(-expand=>1,-fill=>'x');

	@app::procbuts = ();
	$app::noforce = 1;
	my $x = 0;

	push @app::procbuts, $mw->Tk::ProcessButton(
		-text 	=>	'Normalize', 
		-method	=>	'medians')->pack(-expand=>1,-fill=>'x');
	push @app::procbuts, $mw->Tk::ProcessButton(
		-text 	=>	'Replicate Comparison', 
		-method	=>	'replicate_comparison')->pack(-expand=>1,-fill=>'x');
	push @app::procbuts, $mw->Tk::ProcessButton(
		-text 	=>	'Responses', 
		-method	=>	'calculate_response_comparisons')->pack(-expand=>1,-fill=>'x');
	push @app::procbuts, $mw->Tk::ProcessButton(
		-text 	=>	'Cell Differences', 
		-method	=>	'calculate_cell_comparisons')->pack(-expand=>1,-fill=>'x');
	push @app::procbuts, $mw->Tk::ProcessButton(
		-text 	=>	'Differential Responses', 
		-method	=>	'calculate_differential_response_comparisons')->pack(-expand=>1,-fill=>'x');

	$mw->Button(-text=>'Run all',-command=>sub{
		if($app::noforce  &&  -e $App::Config2{'files_outputPath'} &&
			'Ok' ne $mw->messageBox(
				-title =>'File Exists',
				-message => "$App::Config2{'files_outputPath'} already exists!  Overwrite?",
				-type => 'OkCancel',
				-icon => 'warning')){
			return;
		}

		$app::noforce = 0;
		foreach my $but(@app::procbuts){
			my $subarr = $but->cget('-command');
			my $sub = $subarr->[0];
			&$sub();
		}
		$app::noforce = 1;
	})->pack(-expand=>1,-fill=>'x');
	return $mw;
}


sub Tk::ProcessButton {
	my ($w,%opts) = @_; 
	my $method = $opts{-method};
	delete $opts{-method};
	my $button;
	$button = $w->Button(
		%opts, 
		-command => sub {
			if($app::noforce  &&  -e $App::Config2{'files_outputPath'} &&
				'Ok' ne $w->messageBox(
					-title =>'File Exists',
					-message => "$App::Config2{'files_outputPath'} already exists!  Overwrite?",
					-type => 'OkCancel',
					-icon => 'warning')){
				return;
			}
			my $bg = $button->cget('-background');
			$button->configure(-background=>'#ff9900');
			$button->update;
			$app::resp->$method();
			$button->configure(-background=>$bg);
		},
	);
	return $button;
}

sub Tk::FileButton {
	my ($w,%opts) = @_;
	my $label = $opts{'-label'};
	delete $opts{'-label'};
	my $textvariable = $opts{'-textvariable'};
	delete $opts{'-textvariable'};
	my $type = $opts{'-type'};
	delete $opts{'-type'};
	my $cb = $opts{'-callback'};
	delete $opts{'-callback'};
	my $rb = $opts{'-reloadbutton'};
	delete $opts{'-reloadbutton'};
	croak "-type must be one of getOpenFile, getSaveFile or chooseDirectory"
		unless $type =~ /^(?:getOpenFile|getSaveFile|chooseDirectory)$/;
	my $fr = $w;

	my $c = 0;
	my $r = ++$app::filebuttons_row;

	$fr->Label(
		-text => $label
	)->grid(-column=>$c++, -row=>$r, -sticky=>'w');
	$fr->Entry(
		-textvariable => $textvariable
	)->grid(-column=>$c++, -row=>$r, -sticky=>'ew');
	$fr->Button(
		-text=>'...',
		-command => sub {
			my $fn = $w->$type(
				-title=>$label,
				-defaultextension => '.txt',
				-initialdir => $App::Config{'directory'},
				-filetypes => $app::filetypes, %opts);
			App::SetDirectory($fn) if $fn;
			$$textvariable = $fn if $fn;
			&$cb($fn) if $cb && $fn;
		}
	)->grid(-column=>$c++, -row=>$r, -sticky=>'ew');
	$fr->Button(-text=>"reread", -command=>$cb
		)->grid(-column=>$c++, -row=>$r, -sticky=>'ew')
		 if $rb;
	return $fr;
}
