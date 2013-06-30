use strict;
use warnings;
use Test::More;

use mop;

role Explosive {
    method formatter;
    method explode {
        return $self->formatter('Bang');
    }
}

class Bomb (does => 'Explosive') {
    method formatter {
        lc($_[1])
    }
}

class BigBomb (extends => 'Bomb') {
    method formatter {
        uc($_[1])
    }
}

is_deeply(
    Bomb->metaclass->roles,
    { Explosive => Explosive->metaclass },
    'metaclass reports `does` correctly',
);

my $x = BigBomb->new;

can_ok('Explosive', 'explode');
can_ok('Bomb', 'explode');
can_ok('BigBomb', 'explode');
can_ok($x, 'explode');

ok(!'Explosive'->can('new'), 'roles cannot be instantiated');

is($x->explode, 'BANG', 'calls to methods defined in roles work');

ok('Explosive'->DOES('Explosive'), 'Explosive DOES Explosive');
ok('Bomb'->DOES('Explosive'), 'Bomb DOES Explosive');
ok('BigBomb'->DOES('Explosive'), 'BigBomb DOES Explosive');
ok($x->DOES('Explosive'), '$x DOES Explosive');
ok(!'Explosive'->DOES('Bomb'), 'not Explosive DOES Bomb');
ok('Bomb'->DOES('Bomb'), 'Bomb DOES Bomb');
ok('BigBomb'->DOES('Bomb'), 'BigBomb DOES Bomb');
ok($x->DOES('Bomb'), '$x DOES Bomb');
ok(!'Explosive'->DOES('BigBomb'), 'not Explosive DOES BigBomb');
ok(!'Bomb'->DOES('BigBomb'), 'not Bomb DOES BigBomb');
ok('BigBomb'->DOES('BigBomb'), 'BigBomb DOES BigBomb');
ok($x->DOES('BigBomb'), '$x DOES BigBomb');

role Big {
	method be_big {
		return 42;
	}
}

ok(!$x->DOES('Big'), 'role has not been applied yet');

BigBomb->metaclass->apply_roles( 'Big'->metaclass );

ok($x->DOES('Big'), 'role has been applied now');
is($x->be_big, 42, 'late role application works');

done_testing;
