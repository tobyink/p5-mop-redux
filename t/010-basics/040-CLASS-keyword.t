#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

role Bar {
	method m1 { __CLASS__ }
}

class Foo with Bar {
	method m2 { __CLASS__ }
}

is(
	'Bar'->m1,
	'Bar',
);

is(
	'Foo'->m1,
	'Bar',
);

is(
	'Foo'->m2,
	'Foo',
);

like(
	exception { __CLASS__ },
	qr{^Cannot use __CLASS__ outside method},
);

done_testing;