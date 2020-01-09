use File::Temp;
use Test::More tests => 1;
use Spreadsheet::Wright;

my $tmp = File::Temp->new();

SKIP: {
	open FILE, '>', $tmp->filename
		or skip "cannot write to temporary file.", 1;
	close FILE;

	my $h = Spreadsheet::Wright->new(file => $tmp->filename,
									 format => 'json',
									 sheet => 'Discoveries',
									 json_options=>{pretty=>1, canonical=>1});
	$h->addrow('Name', 'Discovery');
	$h->addrows(
		['Archimedes', 'Water displacement'],
		['Albert Einstein', 'General relativity'],
		);
	$h->addsheet('Names');
	$h->addrow( 'Name', 'Surname' );
	$h->addrow( 'Albert', 'Einstein' );
	$h->addrow( 'Leonardo', 'Da Vinci' );
	$h->close;

	my $contents = do { open my($fh), $tmp->filename; local $/ = <$fh>; };

	is($contents, <<'DATA', 'JSON output works');
{
   "Discoveries" : [
      [
         "Name",
         "Discovery"
      ],
      [
         "Archimedes",
         "Water displacement"
      ],
      [
         "Albert Einstein",
         "General relativity"
      ]
   ],
   "Names" : [
      [
         "Name",
         "Surname"
      ],
      [
         "Albert",
         "Einstein"
      ],
      [
         "Leonardo",
         "Da Vinci"
      ]
   ]
}
DATA
}
