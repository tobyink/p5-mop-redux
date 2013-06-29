package mop::class;

use v5.16;
use warnings;

use mop::util qw[ init_attribute_storage ];

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'mop::namespace';

init_attribute_storage(my %__superclass_STORAGE);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self = $class->SUPER::new(@_);
    $__superclass_STORAGE{ $self } = \($args{'superclass'});
    $self;
}

sub superclass { ${ $__superclass_STORAGE{ $_[0] } } }

our $METACLASS;

sub metaclass {
    return $METACLASS if defined $METACLASS;
    require mop::class;
    $METACLASS = mop::class->new(
        name       => 'mop::class',
        version    => $VERSION,
        authority  => $AUTHORITY,
        superclass => 'mop::namespace'
    );

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$superclass', 
        storage => \%__superclass_STORAGE
    ));

    $METACLASS->add_method( mop::method->new( name => 'superclass', body => \&superclass ) );

    $METACLASS;
}

1;
