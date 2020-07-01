# C::Macros [![Build Status](https://travis-ci.org/PerlFFI/C-Macros.svg)](http://travis-ci.org/PerlFFI/C-Macros) ![windows](https://github.com/PerlFFI/C-Macros/workflows/windows/badge.svg) ![macos](https://github.com/PerlFFI/C-Macros/workflows/macos/badge.svg)

Find and evaluate C/C++ macros from Perl

# SYNOPSIS

```perl
use C::Macros;

my $macros = C::Macros->new(
  headers => ['foo.h'],
);

foreach my $macro ($macros->run)
{
  # macro isa C::Macros::Macro
  say "name  = ", $macro->name;
  say "type  = ", $macro->type; # one of: integer, string, float, double or "other"
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
returns the result as a list of [C::Macros::Macro](https://metacpan.org/pod/C::Macros::Macro) instances.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
