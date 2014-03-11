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


$app::top = MainWindow->new();
$app::proteinGroupsPath = '';
$app::annotationsPath = '';
$app::outputPath = '';

%app::selection_controls = ();
%app::columnIndex = ();
$app::filebuttons_row = 0;

$app::H = $app::W = 0;

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
$app::side->FileControls(1)->grid(-sticky=>'we');
$app::side->ProcessControls()->grid(-sticky=>'we');
$app::side->FileControls(2)->grid(-sticky=>'we');

$app::directory = File::HomeDir->my_home;

$app::filter = '';


$app::top->MainLoop;


sub app::resp {
	$app::resp = Bio::MaxQuant::ProteinGroups::Response->new(
		filepath => $app::proteinGroupsPath,
		resultsfile => $app::outputPath,
	);

	$app::side->RefreshColumnFilters();
	App::GenerateColumnFilter();
}

sub App::BrowseCmd {
	($app::x,$app::y) = @_;
	return unless $app::x < $app::W && $app::y < $app::H;
	$app::gridmenu->post($app::tixgrid->pointerx,$app::tixgrid->pointery);
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
			-initialdir => $app::directory,
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
	$app::directory = dirname($fn);
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
#	my $io = IO::File->new($app::outputPath,'r') or return;
#	%app::columnIndex = ();
#	my $tell1 = 0;
#	while(<$io>){
#		my $tell2 = tell($io);
#		my $key = substr($_,0,index($_,"\t"));
#		die if $key =~ /\t/; # because i'll need to fix it if it does!
#		$tell1 += length($key)+1;
#		$app::columnIndex{$key} = [$tell1, $tell2-1];
#		$tell1 = $tell2;
#	}
	App::CollectSelectionOptions();

	my $ff = $f->Panel(-text=>'Filter')->grid(-stick=>'we');
	$ff->Label(-text=>"Use the checkboxes below to modify\nthe filter, or do it manually:")->pack;
	$ff->Entry(-textvariable=>\$app::filter)->pack(-expand=>1,-fill=>'x');
	my $fff = $ff->Frame()->pack(-expand=>1,-fill=>'x');
	$fff->Checkbutton(-text=>'show replicates',-variable=>\$app::show_replicates,-command=>\&App::GenerateColumnFilter)->pack(-expand=>1,-fill=>'x',-side=>'left');
	$fff->Checkbutton(-text=>'show stats',-variable=>\$app::show_stats,-command=>\&App::GenerateColumnFilter)->pack(-expand=>1,-fill=>'x',-side=>'left');
	$ff->Button(-text=>'Apply Filter',-command=>\&App::ApplyFilter)->pack(-expand=>1,-fill=>'x');

	$app::selection_controls{ffpanel} = $ff;

	foreach my $title( sort keys %app::selectionFlags){

		$app::selection_controls{$title} = $f->SelectColumns($title);
		$app::selection_controls{$title}->grid(-sticky=>'we');

	}

 	$app::selection_controls{pg} = 
	 	$f->PGSelect();
	 $app::selection_controls{pg}->grid(-sticky=>'we');


}

sub Tk::PGSelect {
	my $f = shift;
	my $mw = $f->Panel(-text=>'Protein Groups');
	foreach(@app::proteinGroupsHead){
		$mw->Checkbutton(-text=>$_,-variable=>\$app::selectionFlags{PG}->{$_},
			-command=>\&App::GenerateColumnFilter)->grid(-sticky=>'w')
	}
	return $mw;
}

sub App::ParseFilter {
	my @parts = split /\s/, $app::filter;
	my $reps = 0;
	my $stats = 0;
	my %pattern = ();
	foreach my $part(@parts){
		if($part eq 'replicates' || $part eq 'reps'){
			$reps = 1;
		}
		if($part eq 'stats'){
			$stats = 1;
		}
		my ($key,$values) = split /\:/, $part;
		$pattern{$key} = $values;
	}
	my $n1 = $stats ? '1' : 'n';
	my $nk = $reps ? 'n' : 'k';
	
	my ($cells,$conds,$procs,$data,$pg) = map {$pattern{$_}} qw/cells conds procs data pg/;

	$data .= '|data|normalized|medians';
	$data = '.*' if $n1 eq '1';

	my $qr = $nk eq 'n'
		? qr!$n1/s\:[^/]+/n\:(?:$cells)\.(?:$conds)/d\:(?:$procs)/k\:[^/]+/t\:(?:$data)/!
		: qr!$n1/s\:[^/]+/n\:[^/]+/d\:(?:$procs)/k\:(?:$cells)\.(?:$conds)/t\:(?:$data)/!;

	my $qr2 = $n1 eq '1' ? qr!-----! : qr!$pg!;

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

sub App::ApplyFilter {
	my ($F,$P) = App::ParseFilter ();
	App::EmptyGrid();
	my $x = 0;
	$app::leftMargin = 0;

	foreach my $key(@app::proteinGroupsHead){
		next unless $key =~ /$P/;
		my $maxw = 0;
		my @col = @{$app::proteinGroups{$key}};
		my $y = 0;
		foreach ('','','',$key,@col){
			$app::tixgrid->set($x,$y,-text=>$_,
				-style=>$y < 4 ? $app::topmarginstyle : $app::leftmarginstyle);
			my $l = length $_;
			$maxw = $l if $l > $maxw;
			$y ++;
		}
		$app::leftMargin ++;

		$app::tixgrid->sizeColumn($x,-size=> $maxw > 20 ? 100 : 'auto');

		$x++;
	}
	$app::tixgrid->configure(-leftmargin=>$app::leftMargin);
	my $ymax = 0;
	foreach my $key(sort keys %app::columnIndex){
		next unless $key =~ /$F/;
		$key =~ m!/s\:([^/]+)/!; my $s = $1;
		$key =~ m!/d\:([^/]+)/!; my $d = $1;
		$key =~ m!/k\:([^/]+)/!; my $k = $1;
		$key =~ m!/t\:([^/]+)/!; my $t = $1;
		my @col = @{$app::columnIndex{$key}};
		my $y = 0;
		my $maxw = 0;
		foreach ($s,$d,$k,$t,@col){
			$app::tixgrid->set($x,$y,-text=>$_,
				-style=>$y < 4 ? $app::topmarginstyle : $app::mainstyle);
			my $l = length $_;
			$maxw = $l if $l > $maxw;
			$y++;
		}
		$ymax = $y if $y > $ymax;

		$app::tixgrid->sizeColumn($x,-size=> $maxw > 20 ? 100 : 'auto');
		$x++;
	}
	$app::W = $x;
	$app::H = $ymax;


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
	my $size = (stat $app::annotationsPath)[7];
	my $io = IO::File->new($app::annotationsPath,'r') or return;
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
		if($hr->{Contaminant}){
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
	my $size = (stat $app::outputPath)[7];
	my $io = IO::File->new($app::outputPath,'r') or return;
	%app::columnIndex = ();
	my $csv = Text::CSV->new({sep_char=>"\t"});
	while(! eof $io){
		my $line = $csv->getline($io);
		next unless defined $line;
		my ($k, @v) = @$line;
		$app::columnIndex{$k} = \@v;
		$app::progress = int (100*tell($io)/$size);
		$prog->update;
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
		data => \%types,
		processing => \%derivations, 
	);
}

sub App::GenerateColumnFilter {
	my (@cells,@conds,@resps,@diffs,@types,@procs,@pg);
	my %map = ('Cells'=>\@cells, 'Conditions'=>\@conds, 'Differential Responses'=>\@diffs, 
				'Condition Responses'=>\@resps,data=>\@types,processing=>\@procs,
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

	my $showstats = $app::show_stats ? 'stats ' : '';
	my $showreps = $app::show_replicates ? 'reps ' : '';

	$app::filter = $showstats . $showreps
		. "cells:$cells conds:$conds data:$types procs:$procs pg:$pg";

}

# filter eg:  s:normalize|replicates d:

sub Tk::SelectColumns {
	my $f = shift;
	my $title = shift;
	my $mw = $f->Panel(-text=>$title);
	foreach (sort keys %{$app::selectionFlags{$title}}){
		next if $title eq 'data' && /^data$|^medians$|^normalized$/;
		$mw->Checkbutton(-text=>$_,
			-variable=>\$app::selectionFlags{$title}->{$_},
			-command=>\&App::GenerateColumnFilter)
				->grid(-sticky=>'w');
	}
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
	if($set == 1){
		$mw = $f->Panel(-text=>'Files for Processing');
		$mw->FileButton(-label=>'ProteinGroups',-textvariable=>\$app::proteinGroupsPath,-type=>'getOpenFile',-callback=>'')->pack(-expand=>1,-fill=>'x');
		$mw->FileButton(-label=>'Output Results',-textvariable=>\$app::outputPath,-type=>'getSaveFile',-callback=>\&app::resp)->pack(-expand=>1,-fill=>'x');
	}
	elsif($set == 2){
		$mw = $f->Panel(-text=>'Input Files for Analysis');
		$mw->FileButton(-label=>'Output Results',-textvariable=>\$app::outputPath,-type=>'getSaveFile',-callback=>\&App::ReadResultsFile)->pack(-expand=>1,-fill=>'x');
		$mw->FileButton(-label=>'Annotations',-textvariable=>\$app::annotationsPath,-type=>'getOpenFile',-callback=>\&App::ReadPGFile)->pack(-expand=>1,-fill=>'x');
	}
	return $mw;
}
sub Tk::ProcessControls {
	my $f = shift;
	my $mw = $f->Panel(-text=>'Processing');

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
		-text 	=>	'Differential Responses', 
		-method	=>	'calculate_differential_response_comparisons')->pack(-expand=>1,-fill=>'x');

	$mw->Button(-text=>'Run all (force)',-command=>sub{
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
			if($app::noforce  &&  -e $app::outputPath &&
				'Ok' ne $w->messageBox(
					-title =>'File Exists',
					-message => "$app::outputPath already exists!  Overwrite?",
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
				-initialdir => $app::directory,
				-filetypes => $app::filetypes, %opts);
			App::SetDirectory($fn) if $fn;
			$$textvariable = $fn if $fn;
			&$cb($fn) if $cb && $fn;
		}
	)->grid(-column=>$c++, -row=>$r, -sticky=>'ew');
	$fr->Button(-text=>"reread", -command=>$cb
		)->grid(-column=>$c++, -row=>$r, -sticky=>'ew')
		 if $cb;
	return $fr;
}
