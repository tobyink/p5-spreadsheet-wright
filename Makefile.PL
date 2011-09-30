use strict;
use warnings;

use inc::Module::Install;

my $dist = 'Spreadsheet-Wright';
my $fn   = "lib/$dist.pm"; $fn =~ s#-#/#g;

name                $dist;
perl_version_from   $fn;
version_from        $fn;
abstract_from       $fn;
readme_from         $fn;
author              'Toby Inkster <tobyink@cpan.org>';
license             'perl';

recommends          'Archive::Zip'            => 0;
requires            'common::sense'           => 0;
recommends          'DateTime'                => 0;
requires            'Encode'                  => 0;
recommends          'HTML::HTML5::Writer'     => 0;
requires            'IO::File'                => 0;
recommends          'JSON'                    => 0;
recommends          'Spreadsheet::WriteExcel' => 0;
test_requires       'Test::More'              => '0.61';
requires            'Text::CSV'               => 0;
recommends          'XML::LibXML'             => 0;

resources(
	'homepage'   => "https://metacpan.org/release/$dist",
	'repository' => "http://goddamn.co.uk/svn-web/perlmods/browse/$dist/",
	'bugtracker' => "http://rt.cpan.org/Dist/Display.html?Queue=$dist",
	);
	
write_doap_changes;
write_doap_changes_xml;
auto_license;
auto_manifest;

auto_install;
WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
