use File::Temp;
use Test::More tests => 1;
use Spreadsheet::Wright;

my $tmp = File::Temp->new();

SKIP: {
	open FILE, '>', $tmp->filename
		or skip "cannot write to temporary file.", 1;
	close FILE;

	my $h = Spreadsheet::Wright->new(file => $tmp->filename,
									 format => 'html',
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

	my $expected = '<!DOCTYPE html>
<title>Data</title>
<h1>Data</h1>
<table>
  <caption>Discoveries</caption>
  <tbody>
    <tr>
      <td>Name
      <td>Discovery
    <tr>
      <td>Archimedes
      <td>Water displacement
    <tr>
      <td>Albert Einstein
      <td>General relativity
</table>
<table>
  <caption>Names</caption>
  <tbody>
    <tr>
      <td>Name
      <td>Surname
    <tr>
      <td>Albert
      <td>Einstein
    <tr>
      <td>Leonardo
      <td>Da Vinci
</table>
';

	$expected =~ s/ *\n *//sg;
	is($contents, $expected, 'HTML output works');
}
