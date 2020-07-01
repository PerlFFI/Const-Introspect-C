package C::Macros::Macro;

use 5.020;
use Moo;

# ABSTRACT: Class representing a C/C++ pre-processor macro
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PROPERTIES

=head2 name

=cut

has name => (
  is       => 'ro',
  required => 1,
);

=head2 value

=cut

has value => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    die 'todo';
  },
);

=head2 type

=cut

has type => (
  is       => 'ro',
  isa      => sub {
    die "type should be one of: string, integer, float, double or other"
      unless $_[0] =~ /^(string|integer|float|double|other)$/;
  },
  lazy     => 1,
  default  => sub {
    die 'todo';
  },
);

no Moo;

1;
