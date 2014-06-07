package Spreadsheet::Wright::HTML;

use 5.010;
use strictures 1;

BEGIN {
	$Spreadsheet::Wright::HTML::VERSION   = '0.104';
	$Spreadsheet::Wright::HTML::AUTHORITY = 'cpan:TOBYINK';
}

use Carp;
use HTML::HTML5::Writer;

use parent qw(Spreadsheet::Wright::XHTML);

sub _make_output
{
	my $self   = shift;
	my $writer = HTML::HTML5::Writer->new;
	return $writer->document($self->{'document'});
}

1;