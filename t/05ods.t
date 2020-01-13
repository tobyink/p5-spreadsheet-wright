use strict;
use Data::Compare;
use File::Temp;
use Test::More tests => 1;
use Spreadsheet::Read;
use Spreadsheet::Wright;

my $tmp = File::Temp->new( SUFFIX => '.ods' );

my $expected = [
    {
        label => 'Discoveries',
        cell => [
            [ 'Name', 'Archimedes', 'Albert Einstein' ],
            [ 'Discovery', 'Water displacement', 'General relativity' ],
        ],
    },
    {
        label => 'Names',
        cell => [
            [ 'Name', 'Albert', 'Leonardo' ],
            [ 'Surname', 'Einstein', 'Da Vinci' ],
        ],
    },
];

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

	shift @$book;
	for my $sheet (@$book) {
        for my $field (keys %$sheet) {
			next if $field eq 'cell';
			next if $field eq 'label';
			delete $sheet->{$field};
        }
        shift @{$sheet->{cell}};
        $sheet->{cell} = [ map { shift @$_; $_ } @{$sheet->{cell}} ];
    }

    ok(Compare($expected, $book), 'ODS output works');
}
