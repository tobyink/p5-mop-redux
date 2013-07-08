#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

class MyRole (extends => 'mop::role') { }

role Thingable (metaclass => 'MyRole') { }

isa_ok( 
	mop::get_meta('Thingable'), 
	$_, 
	q[mop::get_meta('Thingable')],
) for qw( mop::role MyRole );

done_testing;
