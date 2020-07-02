use Test2::V0 -no_srand => 1;
use Const::Introspect::C;

subtest 'basic' => sub {

  my $macros = Const::Introspect::C->new(
    headers => ['foo.h'],
    extra_cflags => ['-Icorpus/include'],
  );
  isa_ok $macros, 'Const::Introspect::C';

  my %macros = map { $_->name => $_ } $macros->run;

  is(
    \%macros,
    hash {
      field 'FOO(x)' => DNE();
      field FOO1 => object {
        call [ isa => 'Const::Introspect::C::Constant' ] => T();
        call name => 'FOO1';
        call type => 'int';
        call value => 1;
      };
      field FOO2 => object {
        call [ isa => 'Const::Introspect::C::Constant' ] => T();
        call name => 'FOO2';
        call type => 'string';
        call value => 'bar';
      };
      field FOO3 => object {
        call [ isa => 'Const::Introspect::C::Constant' ] => T();
        call name => 'FOO3';
        call type => 'double';
        call value => '1.3';
      };
      field FOO4 => object {
        call [ isa => 'Const::Introspect::C::Constant' ] => T();
        call name => 'FOO4';
        call type => 'float';
        call value => '1.3';
      };
      field FOO5 => object {
        call [ isa => 'Const::Introspect::C::Constant' ] => T();
        call name => 'FOO5';
      };
      etc;
    },
  );

};

subtest 'compute expression type' => sub {

  my @tests = (
    [ 1           => 'int'     ],
    [ '1+2'       => 'int'     ],
    [ '"foo"'     => 'string'  ],
    [ '1.4f'      => 'float'   ],
    [ '1.4'       => 'double'  ],
    [ '(void*)0'  => 'pointer' ],
    [ "'a'"       => 'int'     ],
    [ '1L'        => 'long'    ],
  );

  is(
    Const::Introspect::C->new,
    object {
      call [ compute_expression_type => $_->[0] ] => $_->[1] for @tests;
    },
  );

};

subtest 'compute expression value' => sub {

  my @tests = (
    [ '1+3'       => 'int',     4       ],
    [ '"foo"'     => 'string',  'foo' ],
    [ '1L'        => 'long',    1       ],
    [ '(void*)0L' => 'pointer', U()     ],
  );

  is(
    Const::Introspect::C->new,
    object {
      call [ compute_expression_value => $_->[1], $_->[0] ] => $_->[2] for @tests;
    },
  );

};

done_testing;
