use strict;
use warnings;
use Test::More;

use mop;

role Explosive {
	method explode {
		return 'BANG';
	}
}

class Bomb (does => 'Explosive') { }

class BigBomb (extends => 'Bomb') { }

my $x = BigBomb->new;

can_ok('Explosive', 'explode');
can_ok('Bomb', 'explode');
can_ok('BigBomb', 'explode');
can_ok($x, 'explode', '$x');

ok(!'Explosive'->can('new'), 'roles cannot be instantiated');

is($x->explode, 'BANG', 'calls to methods defined in roles work');

done_testing;
