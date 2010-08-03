package Spreadsheet::Wright::HTML;

our $VERSION = '0.102';

use 5.008;
use base qw'Spreadsheet::Wright::XHTML';
use common::sense;

use HTML::HTML5::Writer;

sub _make_output
{
	my $self   = shift;
	my $writer = HTML::HTML5::Writer->new;
	return $writer->document($self->{'document'});
}

1;