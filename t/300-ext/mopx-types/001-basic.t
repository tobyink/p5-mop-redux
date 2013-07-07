#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
	eval { require Types::Standard }
		or plan skip_all => "test requires Types::Standard";
}

use lib 't/ext/mopx-types';
use mop;
use mopx::types;

use Types::Standard 0.014 -types;

class My::Class (extends => "mop::class", with => "mopx::types") {};

class Foo (metaclass => "My::Class") {
	has $foo (isa => Str);
	method get_foo ()       { $foo };
	method set_foo ($value) { $foo = $value };
}

my $tc = mop::get_meta("Foo")->get_attribute('$foo')->type_constraint;
isa_ok($tc, 'Type::Tiny', '$tc');
ok($tc == Str, '$tc == Str');

is(
	exception { Foo->new(foo => "Hello") },
	undef,
	'no exception when constructing instance with valid data',
);

like(
	exception { Foo->new(foo => []) },
	qr{^\[\] did not pass type constraint "Str"},
	'exception when constructing instance with invalid data',
);

is(
	exception { Foo->new->set_foo("Hello") },
	undef,
	'no exception when calling setter with valid data',
);

like(
	exception { Foo->new->set_foo([]) },
	qr{^\[\] did not pass type constraint "Str"},
	'exception when calling setter with invalid data',
);

done_testing;
