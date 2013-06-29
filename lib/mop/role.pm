package mop::role;

use v5.16;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'mop::namespace';

our $METACLASS;

sub methods_for_class {
    my ($self, $class) = @_;

    my %methods = %{ $self->methods || {} };
    delete $methods{$_} for keys %{ $class->methods || {} };
    delete $methods{$_} for keys %{ $class->submethods || {} };

    return \%methods;
}

sub metaclass {
    return $METACLASS if defined $METACLASS;
    require mop::class;
    $METACLASS = mop::class->new(
        name       => 'mop::role',
        version    => $VERSION,
        authority  => $AUTHORITY,
        superclass => 'mop::namespace'
    );

    $METACLASS->add_method( mop::method->new( name => 'methods_for_class', body => \&methods_for_class ) );
    
    $METACLASS;
}

1;
