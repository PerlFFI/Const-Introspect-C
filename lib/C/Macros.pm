package C::Macros;

use Moo;
use 5.020;
use experimental qw( signatures postderef );
use Ref::Util qw( is_plain_arrayref );
use Config;
use Text::ParseWords ();
use Path::Tiny ();
use Capture::Tiny qw( capture );
use C::Macros::Macro;
use Data::Section::Simple ();
use Template ();
use FFI::Platypus 1.00;
use FFI::Build;

# ABSTRACT: Find and evaluate C/C++ macros from Perl
# VERSION

=head1 SYNOPSIS

 use C::Macros;
 
 my $macros = C::Macros->new(
   headers => ['foo.h'],
 );
 
 foreach my $macro ($macros->run)
 {
   # macro isa C::Macros::Macro
   say "name  = ", $macro->name;
   say "type  = ", $macro->type; # one of: int, string, float, double or "other"
   say "value = ", $macro->value;
 }

=head1 DESCRIPTION

This module provides an interface for finding C/C++ macros from header files, and
computing their values.

=head1 PROPERTIES

=head2 headers

List of C/C++ header files.

=cut

has headers => (
  is      => 'ro',
  isa     => sub { die "headers should be a plain array ref" unless is_plain_arrayref($_[0]) },
  default => sub { [] },
);

=head2 lang

The programming language.  Should be one of C<c> or C<c++>.  The default is C<c>.

=cut

has lang => (
  is      => 'ro',
  isa     => sub {
    die "lang should be one of c or c++" unless $_[0] =~ /^c(|\+\+)$/;
  },
  default => 'c',
);

=head2 cc

The C compiler.  The default is the C compiler used by Perl itself,
automatically split on the appropriate whitespace.
This should be a array reference, so C<['clang']> and not C<'clang'>.
This allows for C<cc> with spaces in it.

=cut

has cc => (
  is      => 'ro',
  default => sub { [Text::ParseWords::shellwords($Config{cc})] },
);

=head2 ppflags

The C pre-processor flags.  This may change in the future, or on some platforms, but as of
this writing this is C<-dM -E -x c> for C and C<-dM -E -x c++> for C++.  This must be an
array reference.

=cut

has ppflags => (
  is      => 'ro',
  lazy    => 1,
  default => sub ($self) {
    ['-dM', '-E', '-x' => $self->lang];
  },
);

=head2 cflags

C compiler flags.  This is what Perl uses by default.  This must be an array reference.

=cut

has cflags => (
  is      => 'ro',
  default => sub { [Text::ParseWords::shellwords($Config{ccflags})] },
);

=head2 extra_cflags

Extra Compiler flags.  This is an empty array by default.  This allows the caller to provide additional
library specific flags, like C<-I>.

=cut

has extra_cflags => (
  is      => 'ro',
  default => sub { [] },
);

=head2 source

C source file.  This is an instance of L<Path::Tiny> and it is created on-the-fly.  You shouldn't
need to specify this explicitly.

=cut

has source => (
  is      => 'ro',
  lazy    => 1,
  default => sub ($self) {
    my $p = Path::Tiny->tempfile(
      TEMPLATE => 'c-macros-XXXXXX',
      SUFFIX   => $self->lang eq 'c' ? '.c' : '.cxx',
    );
    my $fh = $p->openw_utf8;
    say $fh "#include <$_>" for $self->headers->@*;
    close $fh;
    $p;
  },
);

=head2 filter

Filter regular expression that all macro names must match.  This is C<^[^_]> by default, which means
all macros starting with an underscore are skipped.

=cut

has filter => (
  is      => 'ro',
  default => sub {
    qr/^[^_]/;
  },
);

=head1 METHODS

=head2 run

 my @macros = $macros->run;

This generates the source file, runs the pre-processor, parses the macros as well as possible and
returns the result as a list of L<C::Macros::Macro> instances.

=cut

sub run ($self)
{
  my @cmd = (
    map { $_->@* }
    $self->cc,
    $self->ppflags,
    $self->cflags,
    $self->extra_cflags,
  );

  push @cmd, $self->source->stringify;

  my($out, $err, $ret, $sig) = capture {
    system @cmd;
    ($? >> 8,$? & 127);
  };

  if($ret != 0 || $sig != 0)
  {
    # TODO: class exception here
    print $err;
    die "command: @cmd failed";
  }

  my $filter = $self->filter;

  my @macros;

  foreach my $line (split /\n/, $out)
  {
    if($line =~ /^#define\s+(\S+)\s+(.*)\s*$/)
    {
      my $name = $1;
      my $value = $2;
      next if $name =~ /[()]/;
      next unless $name =~ $filter;

      if($value =~ /^-?([1-9][0-9]*|0[0-7]*)$/)
      {
        push @macros, C::Macros::Macro->new(
          name  => $name,
          value => int $value,
          type  => 'int',
        )
      }
      elsif($value =~ /^"([a-z_0-9]+)"$/i)
      {
        push @macros, C::Macros::Macro->new(
          name  => $name,
          value => $1,
          type  => 'string',
        )
      }
      elsif($value =~ /^([0-9]+\.[0-9]+)([Ff]{0,1})$/)
      {
        push @macros, C::Macros::Macro->new(
          name  => $name,
          value => $1,
          type  => $2 ? 'float' : 'double',
        );
      }
      else
      {
        push @macros, C::Macros::Macro->new(
          name  => $name,
        );
      }
    }
    else
    {
      warn "unable to parse line: $line";
    }
  }

  @macros;
}

=head2 compute_expression_type

 my $type = $macros->compute_expression_type($expression);

This attempts to compute the type of the C C<$expression>.  It should
return one of C<int>, C<long>, C<string>, C<float>, C<double>, or C<other>.
If the type cannot be determined then C<other> will be returned, and
often indicates a code macro that doesn't have a  corresponding
constant.

=cut

sub _tt ($self, $name, %args)
{
  state $cache;

  my $template = $cache->{$name} //= do {
    state $dss;
    $dss //= Data::Section::Simple->new(__PACKAGE__);
    $dss->get_data_section($name) // die "no such template: $name";
  };

  state $tt;

  $tt //= Template->new;

  my $output = '';
  $args{self} = $self;
  $tt->process(\$template, \%args, \$output) || die $tt->error;
  $output;
}

# give a unique name for each lib
sub _lib_name ($self, $name)
{
  state $counter = 0;
  $counter++;
  join '', $name, $$, $counter;
}

sub _build_from_template ($self, $name1, $name2, %args)
{
  my $source = Path::Tiny->tempfile(
    TEMPLATE => "$name1-XXXXXX",
    SUFFIX   => $self->lang eq 'c' ? '.c' : '.cxx',
  );
  $source->spew_utf8(
    $self->_tt(
      "$name1.c.tt",
      %args,
    )
  );

  my $libname = $self->_lib_name($name2);

  my $build = FFI::Build->new(
    $libname,
    cflags => $self->extra_cflags,
    export => [$name1 =~ s/-/_/gr],
    source => ["$source"],
  );

  my $lib = $build->build;

  my $ffi = FFI::Platypus->new(
    api => 1,
    lib => [$lib->path],
  );

  ($ffi, $build)
}

sub compute_expression_type ($self, $expression)
{
  my($ffi, $build) = $self->_build_from_template(
    'compute-expression-type',
    'cet',
    expression => $expression,
  );

  my $type = $ffi->function( 'compute_expression_type' => [] => 'string' )
    ->call;

  $build->clean;

  $type;
}

=head2 compute_expression_value

 my $value = $macros->compute_expression_value($type, $expression);

This method attempts to compute the value of the given C C<$expression> of
the given C<$type>.  C<$type> should be one of  C<int>, C<long>, C<string>,
C<float>, or C<double>.

If you do not know the expression type, you can try to compute the type
using C<compute_expression_type> above.

=cut

sub compute_expression_value ($self, $type, $expression)
{
  my $ctype = $type;
  $ctype = 'const char *' if $type eq 'string';
  $ctype = 'void *' if $type eq 'pointer';
  my $ffitype = $type;
  $ffitype = 'opaque' if $type eq 'pointer';

  my($ffi, $build) = $self->_build_from_template(
    'compute-expression-value',
    'cev',
    ctype      => $ctype,
    expression => $expression,
  );

  my $value = $ffi->function( 'compute_expression_value' => [] => $ffitype )
    ->call;

  $build->clean;

  $value;
}

no Moo;

1;

__DATA__

@@ compute-expression-type.c.tt
[% FOREACH header in self.headers %]
#include <[% header %]>
[% END %]
const char *
compute_expression_type()
{
  return _Generic(
    [% expression %],
    float    : "float",
    double   : "double",
    char *   : "string",
    void *   : "pointer",
    int      : "int",
    long     : "long"
  );
}

@@ compute-expression-value.c.tt
[% FOREACH header in self.headers %]
#include <[% header %]>
[% END %]
[% ctype %]
compute_expression_value()
{
  return [% expression %];
}
