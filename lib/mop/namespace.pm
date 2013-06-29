package mop::namespace;

use v5.16;
use warnings;

use mop::util qw[ init_attribute_storage ];

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'mop::object';

init_attribute_storage(my %__name_STORAGE);
init_attribute_storage(my %__version_STORAGE);
init_attribute_storage(my %__authority_STORAGE);
init_attribute_storage(my %__attributes_STORAGE);
init_attribute_storage(my %__methods_STORAGE);
init_attribute_storage(my %__submethods_STORAGE);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self = $class->SUPER::new;
    $__name_STORAGE{ $self }       = \($args{'name'});
    $__version_STORAGE{ $self }    = \($args{'version'});
    $__authority_STORAGE{ $self }  = \($args{'authority'});
    $__attributes_STORAGE{ $self } = \({});
    $__methods_STORAGE{ $self }    = \({});
    $__submethods_STORAGE{ $self } = \({});
    $self;
}

# identity

sub name       { ${ $__name_STORAGE{ $_[0] } } }
sub version    { ${ $__version_STORAGE{ $_[0] } } }
sub authority  { ${ $__authority_STORAGE{ $_[0] } } }

# attributes

sub attribute_class { 'mop::attribute' }

sub attributes { ${ $__attributes_STORAGE{ $_[0] } } }

sub add_attribute {
    my ($self, $attr) = @_;
    $self->attributes->{ $attr->name } = $attr;
}

sub get_attribute {
    my ($self, $name) = @_;
    $self->attributes->{ $name }
}

sub has_attribute {
    my ($self, $name) = @_;
    exists $self->attributes->{ $name };
}

# methods

sub method_class { 'mop::method' }

sub methods { ${ $__methods_STORAGE{ $_[0] } } }

sub add_method {
    my ($self, $method) = @_;
    $self->methods->{ $method->name } = $method;
}

sub get_method {
    my ($self, $name) = @_;
    $self->methods->{ $name }
}

sub has_method {
    my ($self, $name) = @_;
    exists $self->methods->{ $name };
}

# submethods

sub submethod_class { 'mop::method' }

sub submethods { ${ $__submethods_STORAGE{ $_[0] } } }

sub add_submethod {
    my ($self, $submethod) = @_;
    $self->submethods->{ $submethod->name } = $submethod;
}

sub get_submethod {
    my ($self, $name) = @_;
    $self->submethods->{ $name }
}

sub has_submethod {
    my ($self, $name) = @_;
    exists $self->submethods->{ $name };
}

# events

sub FINALIZE {}

our $METACLASS;

sub metaclass {
    return $METACLASS if defined $METACLASS;
    require mop::class;
    $METACLASS = mop::class->new(
        name       => 'mop::namespace',
        version    => $VERSION,
        authority  => $AUTHORITY,
        superclass => 'mop::object'
    );

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$name', 
        storage => \%__name_STORAGE
    ));

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$version', 
        storage => \%__version_STORAGE
    ));

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$authority', 
        storage => \%__authority_STORAGE
    ));

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$attributes', 
        storage => \%__attributes_STORAGE,
        default => \({})
    ));

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$methods', 
        storage => \%__methods_STORAGE,
        default => \({})
    ));

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$submethods', 
        storage => \%__submethods_STORAGE,
        default => \({})
    ));

    # NOTE:
    # we do not include the new method, because
    # we want all meta-extensions to use the one
    # from mop::object.
    # - SL
    $METACLASS->add_method( mop::method->new( name => 'name',       body => \&name       ) );
    $METACLASS->add_method( mop::method->new( name => 'version',    body => \&version    ) );   
    $METACLASS->add_method( mop::method->new( name => 'authority',  body => \&authority  ) );

    $METACLASS->add_method( mop::method->new( name => 'attribute_class', body => \&attribute_class    ) );
    $METACLASS->add_method( mop::method->new( name => 'attributes',      body => \&attributes    ) );
    $METACLASS->add_method( mop::method->new( name => 'get_attribute',   body => \&get_attribute ) );
    $METACLASS->add_method( mop::method->new( name => 'add_attribute',   body => \&add_attribute ) );
    $METACLASS->add_method( mop::method->new( name => 'has_attribute',   body => \&has_attribute ) );

    $METACLASS->add_method( mop::method->new( name => 'method_class', body => \&method_class    ) );
    $METACLASS->add_method( mop::method->new( name => 'methods',      body => \&methods    ) );
    $METACLASS->add_method( mop::method->new( name => 'get_method',   body => \&get_method ) );
    $METACLASS->add_method( mop::method->new( name => 'add_method',   body => \&add_method ) );
    $METACLASS->add_method( mop::method->new( name => 'has_method',   body => \&has_method ) );

    $METACLASS->add_method( mop::method->new( name => 'submethod_class', body => \&submethod_class    ) );
    $METACLASS->add_method( mop::method->new( name => 'submethods',      body => \&submethods    ) );
    $METACLASS->add_method( mop::method->new( name => 'get_submethod',   body => \&get_submethod ) );
    $METACLASS->add_method( mop::method->new( name => 'add_submethod',   body => \&add_submethod ) );
    $METACLASS->add_method( mop::method->new( name => 'has_submethod',   body => \&has_submethod ) );

    $METACLASS->add_method( mop::method->new( name => 'FINALIZE', body => \&FINALIZE ) );

    $METACLASS;
}

1;

__END__