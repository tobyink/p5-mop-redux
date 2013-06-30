use strict;
use warnings;
use Test::More;

use mop;

role Explosive (required_methods => [qw/format/]) {
    method explode {
        return $self->format('bang');
    }
}

class Bomb (does => 'Explosive') {
    method format {
        lc($_[1])
    }
}

class BigBomb (extends => 'Bomb') {
    method format {
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

done_testing;
