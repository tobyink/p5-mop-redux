package mop::class;

use v5.16;
use warnings;

use mop::util qw[ init_attribute_storage ];

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'mop::namespace';

init_attribute_storage(my %__superclass_STORAGE);
init_attribute_storage(my %__roles_STORAGE);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self = $class->SUPER::new(@_);
    $__superclass_STORAGE{ $self } = \($args{'superclass'});
    $__roles_STORAGE{ $self }      = \($args{'roles'} || []);
    $self;
}

sub superclass { ${ $__superclass_STORAGE{ $_[0] } } }
sub roles      { ${ $__roles_STORAGE{ $_[0] } } }

sub apply_roles {
    my ($self, @roles) = @_;

    my %composed_methods;
    for my $role (@roles) {
        die "not a role: $role" unless defined($role) && $role->isa('mop::role');
        
        my %role_methods = %{ $role->methods_for_class($self) };
        for my $method (sort keys %role_methods) {
            die "roles conflict" if exists $composed_methods{$method};
            $composed_methods{$method} = $role_methods{$method};
        }
    }

    my @all_methods = (
        values(%{$self->methods}),
        values(%composed_methods)
    );
    $_->check_required_methods(\@all_methods) for @roles;

    $self->add_method($_) for values %composed_methods;
}

sub FINALIZE {
    my $self = shift;
    $self->apply_roles(map mop::util::find_meta($_), @{$self->roles});
}

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

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$roles', 
        storage => \%__roles_STORAGE
    ));

    $METACLASS->add_method( mop::method->new( name => 'superclass', body => \&superclass ) );
    $METACLASS->add_method( mop::method->new( name => 'roles',      body => \&roles ) );

    $METACLASS->add_method( mop::method->new( name => 'FINALIZE',   body => \&FINALIZE ) );

    $METACLASS;
}

1;
