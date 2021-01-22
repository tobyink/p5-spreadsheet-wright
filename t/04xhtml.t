use File::Temp;
use Test::More tests => 1;
use Spreadsheet::Wright;

my $tmp = File::Temp->new();

SKIP: {
	open FILE, '>', $tmp->filename
		or skip "cannot write to temporary file.", 1;
	close FILE;

	my $h = Spreadsheet::Wright->new(file => $tmp->filename,
									 format => 'xhtml',
									 sheet => 'Discoveries');
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

	my $expected = '<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Data</title>
  </head>
  <body>
    <h1>Data</h1>
    <table>
      <caption>Discoveries</caption>
      <tbody>
        <tr>
          <td>Name</td>
          <td>Discovery</td>
        </tr>
        <tr>
          <td>Archimedes</td>
          <td>Water displacement</td>
        </tr>
        <tr>
          <td>Albert Einstein</td>
          <td>General relativity</td>
        </tr>
      </tbody>
    </table>
    <table>
      <caption>Names</caption>
      <tbody>
        <tr>
          <td>Name</td>
          <td>Surname</td>
        </tr>
        <tr>
          <td>Albert</td>
          <td>Einstein</td>
        </tr>
        <tr>
          <td>Leonardo</td>
          <td>Da Vinci</td>
        </tr>
      </tbody>
    </table>
  </body>
</html>
';

	$expected =~ s/([^\?])>\s+</$1></sg;
	is($contents, $expected, 'XHTML output works');
}
