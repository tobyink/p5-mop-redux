package mop::role;

use v5.16;
use warnings;

use mop::util qw[ init_attribute_storage ];

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'mop::namespace';

init_attribute_storage(my %__required_methods_STORAGE);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self = $class->SUPER::new(@_);
    $__required_methods_STORAGE{ $self } = \($args{'required_methods'} || []);
    $self;
}

# A list of methods that this
# role would install into a
# class.
sub methods_for_class {
    my ($self, $class) = @_;

    my %methods = %{ $self->methods || {} };
    delete $methods{$_} for keys %{ $class->methods || {} };
    delete $methods{$_} for keys %{ $class->submethods || {} };

    return \%methods;
}

sub required_methods { ${ $__required_methods_STORAGE{ $_[0] } } }

sub add_required_method {
    my ($self, $name) = @_;
    push @{ $self->required_methods }, $name
        unless $self->has_required_method($name);
}

sub has_required_method {
    my ($self, $name) = @_;
    scalar grep { $_ eq $name } @{ $self->required_methods };
}

sub check_required_methods {
    my ($self, $provided) = @_;

    my %requires = map { $_ => 1 } @{ $self->required_methods || [] };
    delete $requires{$_} for map $_->name, @$provided;

    die $self->name . " requires: " . join(",", sort keys %requires)
        if keys %requires;
}

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

    $METACLASS->add_attribute(mop::attribute->new( 
        name    => '$required_methods', 
        storage => \%__required_methods_STORAGE
    ));

    $METACLASS->add_method( mop::method->new( name => 'methods_for_class', body => \&methods_for_class ) );

    $METACLASS->add_method( mop::method->new( name => 'required_methods',      body => \&required_methods ) );
    $METACLASS->add_method( mop::method->new( name => 'add_required_method',   body => \&add_required_method ) );
    $METACLASS->add_method( mop::method->new( name => 'has_required_method',   body => \&has_required_method ) );
    $METACLASS->add_method( mop::method->new( name => 'check_required_method', body => \&check_required_method ) );

    $METACLASS;
}

1;
