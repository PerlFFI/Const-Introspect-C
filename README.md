# Const::Introspect::C [![Build Status](https://travis-ci.org/PerlFFI/Const-Introspect-C.svg)](http://travis-ci.org/PerlFFI/Const-Introspect-C) ![windows](https://github.com/PerlFFI/Const-Introspect-C/workflows/windows/badge.svg) ![macos](https://github.com/PerlFFI/Const-Introspect-C/workflows/macos/badge.svg)

Find and evaluate C/C++ macros from Perl

# SYNOPSIS

```perl
use Const::Introspect::C;

my $macros = Const::Introspect::C->new(
  headers => ['foo.h'],
);

foreach my $macro ($macros->run)
{
  # macro isa Const::Introspect::C::Constant
  say "name  = ", $macro->name;
  say "type  = ", $macro->type; # one of: int, string, float, double or "other"
  say "value = ", $macro->value;
}
```

# DESCRIPTION

This module provides an interface for finding C/C++ macros from header files, and
computing their values.

# PROPERTIES

## headers

List of C/C++ header files.

## lang

The programming language.  Should be one of `c` or `c++`.  The default is `c`.

## cc

The C compiler.  The default is the C compiler used by Perl itself,
automatically split on the appropriate whitespace.
This should be a array reference, so `['clang']` and not `'clang'`.
This allows for `cc` with spaces in it.

## ppflags

The C pre-processor flags.  This may change in the future, or on some platforms, but as of
this writing this is `-dM -E -x c` for C and `-dM -E -x c++` for C++.  This must be an
array reference.

## cflags

C compiler flags.  This is what Perl uses by default.  This must be an array reference.

## extra\_cflags

Extra Compiler flags.  This is an empty array by default.  This allows the caller to provide additional
library specific flags, like `-I`.

## source

C source file.  This is an instance of [Path::Tiny](https://metacpan.org/pod/Path::Tiny) and it is created on-the-fly.  You shouldn't
need to specify this explicitly.

## filter

Filter regular expression that all macro names must match.  This is `^[^_]` by default, which means
all macros starting with an underscore are skipped.

# METHODS

## run

```perl
my @macros = $macros->run;
```

This generates the source file, runs the pre-processor, parses the macros as well as possible and
returns the result as a list of [Const::Introspect::C::Constant](https://metacpan.org/pod/Const::Introspect::C::Constant) instances.

## compute\_expression\_type

```perl
my $type = $macros->compute_expression_type($expression);
```

This attempts to compute the type of the C `$expression`.  It should
return one of `int`, `long`, `string`, `float`, `double`, or `other`.
If the type cannot be determined then `other` will be returned, and
often indicates a code macro that doesn't have a  corresponding
constant.

## compute\_expression\_value

```perl
my $value = $macros->compute_expression_value($type, $expression);
```

This method attempts to compute the value of the given C `$expression` of
the given `$type`.  `$type` should be one of  `int`, `long`, `string`,
`float`, or `double`.

If you do not know the expression type, you can try to compute the type
using `compute_expression_type` above.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
