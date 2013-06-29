package mop::role;

use v5.16;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'mop::namespace';

our $METACLASS;

sub metaclass {
    return $METACLASS if defined $METACLASS;
    require mop::class;
    $METACLASS = mop::class->new(
        name       => 'mop::role',
        version    => $VERSION,
        authority  => $AUTHORITY,
        superclass => 'mop::namespace'
    );

    $METACLASS;
}

1;
