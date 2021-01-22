use File::Temp;
use Test::More tests => 1;
use Spreadsheet::Wright;

my $tmp = File::Temp->new();

SKIP: {
	open FILE, '>', $tmp->filename
		or skip "cannot write to temporary file.", 1;
	close FILE;

	my $h = Spreadsheet::Wright->new(file => $tmp->filename, csv_options=>{eol=>"\n"});
	$h->addrow('Name', 'Discovery');
	$h->addrows(
		['Archimedes', 'Water displacement'],
		['Albert Einstein', 'General relativity'],
		);
	$h->close;

	my $contents = do { open my($fh), $tmp->filename; local $/ = <$fh>; };

	is($contents, <<'DATA', 'CSV output works');
Name,Discovery
Archimedes,"Water displacement"
"Albert Einstein","General relativity"
DATA
}

