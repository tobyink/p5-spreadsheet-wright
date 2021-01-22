use Test::More tests => 1;
use Spreadsheet::Wright;

SKIP: {
	my $contents;
	open my $handle, '>', \$contents
		or skip "cannot open a filehandle to string.", 1;

	my $h = Spreadsheet::Wright->new(filehandle => $handle, format => 'csv',
									 csv_options=>{eol=>"\n"});
	$h->addrow('Name', 'Discovery');
	$h->addrows(
		['Archimedes', 'Water displacement'],
		['Albert Einstein', 'General relativity'],
		);
	$h->close;

	is($contents, <<'DATA', 'CSV output to filehandle works');
Name,Discovery
Archimedes,"Water displacement"
"Albert Einstein","General relativity"
DATA

	unlink $FN;
}

