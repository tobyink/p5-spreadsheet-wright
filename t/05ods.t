use strict;
use File::Temp;
use Test::More tests => 4;
use Spreadsheet::Read;
use Spreadsheet::Wright;

my $tmp = File::Temp->new( SUFFIX => '.ods' );

SKIP: {
	open FILE, '>', $tmp->filename
		or skip "cannot write to temporary file.", 1;
	close FILE;

	my $h = Spreadsheet::Wright->new(file => $tmp->filename,
									 format => 'ods',
									 sheet => 'Discoveries');
	$h->addrow('Name', 'Discovery');
	$h->addrows(
		['Archimedes', 'Water displacement'],
		['Albert Einstein', 'General relativity'],
		);
	$h->addsheet('Names');
	$h->addrow( 'Name', 'Surname' );
	$h->addrows(
		[ 'Albert', 'Einstein' ],
		[ 'Leonardo', 'Da Vinci' ],
		);
	$h->close;

	my $book = ReadData( $tmp->filename, parser => 'sxc' );
	is($book->[0]{sheets}, 2, 'correct number of sheets');
	is($book->[1]{label}, 'Discoveries', 'correct sheet name');
	is($book->[2]{label}, 'Names', 'correct sheet name');
	is($book->[1]{cell}[1][2], 'Archimedes', 'correct cell content');
}
