use strict;
use warnings;
use Test::More;

use mop;

class Thing1 {
	has $name;
	method name is overload(q[""]) {
		return $name;
	}
}

class Thing2 extends Thing1 is overload('inherited') {
	method name {
		return uc($self->next::method);
	}
}

class Thing3 {
	has $name is overload(q[""]);
}

class Thing4 extends Thing3 is overload('inherited') { }

my $thing1 = 'Thing1'->new(name => 'foo');
is("$thing1", 'foo');

{
	local $TODO = "this doesn't work... maybe it's not supposed to";
	my $thing2 = 'Thing2'->new(name => 'bar');
	is("$thing2", 'BAR');
}

my $thing3 = 'Thing3'->new(name => 'baz');
is("$thing3", 'baz');

my $thing4 = 'Thing4'->new(name => 'quux');
is("$thing4", 'quux');

done_testing;
