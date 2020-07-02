package C::Macros::Macro;

use 5.020;
use Moo;

# ABSTRACT: Class representing a C/C++ pre-processor macro
# VERSION

=head1 DESCRIPTION

This class represents a single C/C++ pre-processor macro.  See L<C::Macros> for the
interface for getting a list of these macros.

=head1 PROPERTIES

=head2 name

The name of the macro.

=cut

has name => (
  is       => 'ro',
  required => 1,
);

=head2 value

The value of the macro.  The representation may depend on the C<type>, or for
C<other> type macros (typically for code macros), there is no sensible value,
and this will be C<undef>.

=cut

has value => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    die 'todo';
  },
);

=head2 type

The macro type.  This will be one of: C<string>, C<int>, C<long>, C<pointer>, C<float>,
C<double> or C<other>.

=cut

has type => (
  is       => 'ro',
  isa      => sub {
    die "type should be one of: string, int, long, pointer, float, double or other"
      unless $_[0] =~ /^(string|int|long|pointer|float|double|other)$/;
  },
  lazy     => 1,
  default  => sub {
    die 'todo';
  },
);

no Moo;

1;
