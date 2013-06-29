package mop::object;

use v5.16;
use warnings;

use mop::util    qw[ find_meta get_object_id ];
use Scalar::Util qw[ blessed ];

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless \(my $x) => $class;

    # NOTE:
    # prior to the bootstrapping being
    # finished, we need to not try and 
    # build classes, it will all be done
    # manually in the mop:: classes.
    # - SL
    return $self unless $mop::BOOTSTRAPPED;
    
    my @mro = @{ mop::mro::get_linear_isa($class) };

    my %attributes = map { 
        if (my $m = find_meta($_)) {
            %{ $m->attributes }
        }
        else {
            qw()
        }
    } reverse @mro;

    foreach my $attr (values %attributes) { 
        if ( exists $args{ $attr->key_name }) {
            $attr->store_data_in_slot_for( $self, $args{ $attr->key_name } )
        } else {
            $attr->store_default_in_slot_for( $self );
        }
    }

    foreach my $class (reverse @mro) {
        if (my $m = find_meta($class)) {
            $m->get_submethod('BUILD')->execute($self, [ \%args ]) 
                if $m->has_submethod('BUILD');
        }
    }

    $self;
}

sub id { get_object_id( shift ) }

sub dump {
    my $self = shift;

    my %attributes = map { 
        if (my $m = find_meta($_)) {
            %{ $m->attributes }
        }
    } reverse @{ mop::mro::get_linear_isa($self) };

    my $temp = {
        __ID__    => get_object_id($self),
        __CLASS__ => find_meta($self)->name
    };

    foreach my $attr (values %attributes) { 
        if ($attr->name eq '$storage') {
            $temp->{ $attr->name } = '__INTERNAL_DETAILS__';
        } else {
            $temp->{ $attr->name } = _dumper( 
                $attr->fetch_data_in_slot_for( $self )
            );    
        }
    }

    $temp;
}

sub _dumper {
    my ($data) = @_;
    if (blessed($data)) {
        return $data->dump;            
    } elsif (ref $data) {
        if (ref $data eq 'ARRAY') {
            return [ map { _dumper( $_ ) } @$data ];
        } elsif (ref $data eq 'HASH') {
            return { map { $_ => _dumper( $data->{$_} ) } keys %$data };     
        } else {
            return $data;            
        }
    } else {
        return $data;            
    }
}

sub DESTROY {
    my $self = shift;
    foreach my $class (@{ mop::mro::get_linear_isa($self) }) {
        if (my $m = find_meta($class)) {
            $m->get_submethod('DEMOLISH')->execute($self, []) 
                if $m->has_submethod('DEMOLISH');
        }
    }    
}

our $METACLASS;

sub metaclass {
    return $METACLASS if defined $METACLASS;
    require mop::class;
    $METACLASS = mop::class->new( 
        name      => 'mop::object',
        version   => $VERSION,
        authority => $AUTHORITY,
    );
    $METACLASS->add_method( mop::method->new( name => 'new',       body => \&new ) );
    $METACLASS->add_method( mop::method->new( name => 'id',        body => \&id ) );
    $METACLASS->add_method( mop::method->new( name => 'dump',      body => \&dump ) );
    $METACLASS->add_method( mop::method->new( name => 'metaclass', body => \&metaclass ) );
    $METACLASS->add_method( mop::method->new( 
        name => 'isa', 
        body => sub {
            my ($self, $class) = @_;
            scalar grep { $class eq $_ } @{ mop::mro::get_linear_isa($self) }
        } 
    ));
    $METACLASS->add_method( mop::method->new( 
        name => 'can', 
        body => sub {
            my ($self, $method_name) = @_;
            if (my $method = mop::internals::mro::find_method($self, $method_name)) {
                return blessed($method) ? $method->body : $method;
            }
        } 
    ));
    $METACLASS->add_method( mop::method->new( name => 'DESTROY', body => \&DESTROY ) );
    $METACLASS;
}

1;

__END__