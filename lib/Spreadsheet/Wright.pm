=head1 NAME

Spreadsheet::Wright - simple spreadsheet worker

=head1 SYNOPSIS

    # EXCEL spreadsheet

    use Spreadsheet::Wright;

    my $h=Spreadsheet::Wright->new(
        file    => 'spreadsheet.xls',
        format  => 'xls',
        sheet   => 'Products',
        styles  => {
            money   => '($#,##0_);($#,##0)',
        },
    );

    $h->addrow('foo',{
        content         => 'bar',
        type            => 'number',
        style           => 'money',
        font_weight     => 'bold',
        font_color      => 42,
        font_face       => 'Times New Roman',
        font_size       => 20,
        align           => 'center',
        valign          => 'vcenter',
        font_decoration => 'strikeout',
        font_style      => 'italic',
    });
    $h->addrow('foo2','bar2');
    $h->freeze(1,0);

    # CSV file

    use Spreadsheet::Wright;

    my $h=Spreadsheet::Wright->new(
        file        => 'file.csv',
        encoding    => 'iso8859',
    );
    die $h->error() if $h->error;
    $h->addrow('foo','bar');

=head1 DESCRIPTION

C<Spreadsheet::Wright> is a fork of L<Spreadsheet::Write> and
may be used as a drop-in replacement.

C<Spreadsheet::Wright> writes files in CSV, Microsoft Excel,
HTML and OpenDocument formats. It is especially suitable
for building various dumps and reports where rows are built
in sequence, one after another.

It is not especially suitable for modifying existing files.

The name is a not just pun on "write" - the word "wright" means
worker or crafter, and C<Spreadsheet::Wright> does a lot of the
work of spreadsheet output for you!

=head2 Constructor

=over 4

=cut

###############################################################################
package Spreadsheet::Wright;

our $VERSION = '0.102';

use 5.008;
use common::sense;

use IO::File;

sub version {
  return $VERSION;
}
###############################################################################

=item C<< Spreadsheet::Wright->new(%args) >>

    $spreadsheet = Spreadsheet::Wright->new(
        file            => 'table.xls',
        styles          => {
            mynumber        => '#,##0.00',
        }
    );

Creates a new spreadsheet object. It takes a list of options. The
following are valid:

=over 4

=item * B<file> - filename of the new spreadsheet (mandatory)

=item * B<encoding> - encoding of output file (optional, csv format only)

=item * B<format> - format of spreadsheet - 'csv', 'xls', 'html', 'xhtml', 'xml', 'ods', 'json' or 'auto' (default).

=item * B<sheet> - first sheet name (optional, not supported by some formats)

=item * B<styles> - defines cell formatting shortcuts (optional)

=item * B<failsafe> - boolean - if true, falls back to CSV in emergencies

=back

If file format is 'auto' (or omitted), the format is guessed from the
filename extension, defaulting to 'csv'.

=back

=cut

sub new(@)
{
	my ($class, %args) = @_;
	
	my $format   = $args{'format'} || 'auto';
	my $filename = $args{'file'}   || $args{'filename'};
	
	if (lc $format eq 'auto')
	{
		$format = ($filename=~/\.(.+)$/) ? lc($1) : 'auto';
	}
	
	my $implementation = {
		auto    => 'CSV',
		csv     => 'CSV',
		excel   => 'Excel',
		html    => 'HTML',
		json    => 'JSON',
		ods     => 'OpenDocument',
		odsxml  => 'OpenDocumentXML',
		text    => 'CSV',
		txt     => 'CSV',
		xhtml   => 'XHTML',
		xls     => 'Excel',
		xml     => 'OpenDocumentXML',
		}->{lc $format};
	
	my $self = eval
	{
		die "Format $format is not supported" unless $implementation;
		$implementation = join '::', (__PACKAGE__, $implementation);	
		eval "use $implementation;";
		die $@ if $@;
		return $implementation->new(%args);
	};
	
	if ($self && !$@)
	{
		return $self;
	}
	elsif ($args{'failsafe'})
	{
		$implementation = join '::', (__PACKAGE__, 'CSV');
		eval "use $implementation;";
		die $@ if $@;
		return $implementation->new(%args);
	}
	elsif ($@)
	{
		die $@;
	}
	else
	{
		die "Could not instantiate spreadsheet!\n";
	}
}

###############################################################################

sub DESTROY {
    my $self=shift;
    $self->close();
}

###############################################################################

sub error {
    my $self=shift;
    return $self->{'_ERROR'};
}

###############################################################################

sub _open($)
{
	my $self=shift;

	$self->{'_CLOSED'} && die "Can't reuse a closed spreadsheet";

	my $fh = $self->{'_FH'};

	if(!$fh)
	{
		my $filename = $self->{'_FILENAME'} || return undef;
		$fh=new IO::File;
		$fh->open($filename,"w") || die "Can't open file $filename for writing: $!";
		$self->{'_FH'}=$fh;
	}

	return $self->_prepare;
}

sub _prepare { return $_[0]; };

###############################################################################

=head2 Methods

=over 4

=item C<< addrow($cell1,$cell2,...) >>

Adds a row into the spreadsheet. Takes arbitrary number of
arguments. Arguments represent cell values and may be strings or hash
references. If an argument is a hash reference, it takes the following
structure:

    content         value to put into cell
    style           formatting style, as defined in new()
    type            type of the content (defaults to 'auto')
    format          number format (see Spreadsheet::WriteExcel for details)
    font_weight     weight of font. Only valid value is 'bold'
    font_style      style of font. Only valid value is 'italic'
    font_decoration 'underline' or 'strikeout' (or both, space separated)
    font_face       font of column; default is 'Arial'
    font_color      color of font (see Spreadsheet::WriteExcel for color values)
    font_size       size of font
    align           alignment
    valign          vertical alignment
    width           column width, excel units (only makes sense once per column)
    header          boolean; is this cell a header?

Styles can be used to assign default values for any of these formatting
parameters thus allowing easy global changes. Other parameters specified
override style definitions.

Example:

    my $sp=Spreadsheet::Wright->new(
        file        => 'employees.xls',
        styles      => {
            important => { font_weight => 'bold' },
        },
    );
    $sp->addrow(
        { content => 'First Name', font_weight => 'bold' },
        { content => 'Last Name',  font_weight => 'bold' },
        { content => 'Age',        style => 'important' },
    );
    $sp->addrow("John","Doe",34);
    $sp->addrow("Susan","Smith",28);

Note that in this example all header cells will have identical
formatting even though some use direct formats and one uses
style.

If you want to store text that looks like a number you might want to use
{ type => 'string', format => '@' } arguments. By default the type detection
is automatic, as done by for instance L<Spreadsheet::WriteExcel> write()
method.

It is also possible to supply an array reference in the 'content'
parameter of the extended format. It means to use the same formatting
for as many cells as there are elements in this array. Useful for
creating header rows. For instance, the above example can be rewritten
as:

    $sp->addrow(
        { style => 'important',
          content => [ 'First Name','Last Name','Age' ],
        }
    );

Not all styling options are supported in all formats.

=cut

sub addrow (@)
{
	my $self = shift;
	$self->_open() || return undef;
	
	my @cells;
	
	foreach my $item (@_)
	{
		if (ref $item eq 'HASH')
		{
			if (ref $item->{content} eq 'ARRAY')
			{
				foreach my $i (@{ $item->{'content'} })
				{
					my %newitem = %$item;
					$newitem{'content'} = $i;
					push @cells, \%newitem;
				}
			}
			else
			{
				push @cells, $item;
			}
		}
		else
		{
			push @cells, { content => $item };
		}
	}
	
	return $self->_add_prepared_row(@cells);	
}

sub _add_prepared_row { return $_[0]; };

###############################################################################

=item C<< addrows([$cell1A,$cell1B,...],[$cell2A,$cell2B,...],...) >>

Shortcut for adding multiple rows.

Each argument is an arrayref representing a row.

Any argument that is not a reference (i.e. a scalar) is taken to be the
title of a new worksheet.

=cut

sub addrows (@)
{
	my $self = shift;
	foreach my $row (@_)
	{
		if (ref $row eq 'ARRAY')
		{
			$self->addrow(@$row);
		}
		elsif (!ref $row)
		{
			$self->addsheet($row);
		}
		else
		{
			warn "Could not add row.";
		}
	}
	return $self;
}


###############################################################################

=item C<< addsheet($name) >>

Adds a new sheet into the document and makes it active. Subsequent
addrow() calls will add rows to that new sheet.

For CSV format this call is NOT ignored, but produces a fatal error
currently.

=cut

sub addsheet ($$)
{
	die "addsheet not implemented!!\n";
}

###############################################################################

=item C<< freeze($row, $col, $top_row, $left_col) >>

Sets a freeze-pane at the given position, equivalent to Spreadsheet::WriteExcel->freeze_panes().
Only implemented for Excel spreadsheets so far.

=cut

sub freeze { return $_[0]; }

###############################################################################

=item C<< close() >>

Saves the spreadsheet to disk (some of the modules save incrementally anyway) and
closes the file. Calling this explicitly is usually un-necessary, as the Perl garbage collector
will do the job eventually anyway. Once a spreadsheet is closed, calls to addrow() will
fail.

=back

=cut

sub close {}

1;
__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Spreadsheet::Write>.

=head1 AUTHORS

Toby Inkster <tobyink@cpan.org>

Excel and CSV output based almost entirely on work by
Nick Eremeev <nick.eremeev@gmail.com> L<http://ejelta.com/>.

=head1 COPYRIGHT AND LICENCE

Copyright 2007 Nick Eremeev.

Copyright 2010 Toby Inkster.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
