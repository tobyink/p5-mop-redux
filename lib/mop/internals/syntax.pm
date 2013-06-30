package mop::internals::syntax;

use v5.16;
use warnings;

use base 'Devel::Declare::Context::Simple';

use Hash::Util::FieldHash qw[ fieldhash ];
use Variable::Magic       qw[ wizard ];

use Sub::Name      ();
use Devel::Declare ();
use B::Hooks::EndOfScope;

# keep the local package name around
fieldhash my %CURRENT_CLASS_NAME;

# Keep a list of attributes currently 
# being compiled in the class because 
# we need to alias them in the method 
# preamble.
fieldhash my %CURRENT_ATTRIBUTE_LIST;

# So this will apply magic to the aliased
# attributes that we put in the method 
# preamble. For `data`, it takes an ARRAY-ref
# containing the invocant and a ref for the 
# fieldhash that stores our data. Then
# when our attribute variable is written to
# it will also write that same data back to 
# the fieldhash storage.
our $WIZARD = Variable::Magic::wizard(
    data => sub { $_[1] },
    set  => sub { $_[1]->[1]->{ $_[1]->[0] } = $_[0] },
);

sub setup_for {
    my $class = shift;
    my $pkg   = shift;
    {
        no strict 'refs';
        *{ $pkg . '::class'     } = sub (&@) {};
        *{ $pkg . '::role'      } = sub (&@) {};
        *{ $pkg . '::has'       } = sub ($@) {};
        *{ $pkg . '::method'    } = sub (&)  {};
        *{ $pkg . '::submethod' } = sub (&)  {};
    }

    my $context = $class->new;
    Devel::Declare->setup_for(
        $pkg,
        {
            'class'     => { const => sub { $context->class_parser( @_ )     } },
            'role'      => { const => sub { $context->role_parser( @_ )     } },
            'has'       => { const => sub { $context->attribute_parser( @_ ) } },
            'method'    => { const => sub { $context->method_parser( @_ )    } },
            'submethod' => { const => sub { $context->submethod_parser( @_ ) } },
        }
    );
}

sub role_parser {
    my $self = shift;
    $self->init( @_ );
    $self->_namespace_parser('build_role');
}

sub class_parser {
    my $self = shift;
    $self->init( @_ );
    $self->_namespace_parser('build_class');
}

sub _namespace_parser {
    my $self = shift;
    my ($builder_method) = @_;

    $self->skip_declarator;

    my $name   = $self->strip_name;
    my $proto  = $self->strip_proto;
    my $caller = $self->get_curstash_name;
    my $pkg    = ($caller eq 'main' ? $name : (join "::" => $caller, $name));

    $CURRENT_CLASS_NAME{$self}     = $pkg;
    $CURRENT_ATTRIBUTE_LIST{$self} = [];

    # The class preamble is pretty simple, we 
    # evaluate the package into existence, then
    # set it to use our custom MRO, then build
    # our metaclass.
    my $inject = $self->scope_injector_call
        . 'my $d = shift;'
        . 'eval(q[package ' . $pkg .';use strict;use warnings;]);'
        . 'mro::set_mro(q[' . $pkg . '], q[mop]);'
        . '$' . $pkg . '::METACLASS = ' . __PACKAGE__ . '->' . $builder_method . '('
            . 'name => q[' . $pkg . ']' 
            . ($proto ? (', ' . $proto) : '') 
        . ');'
        . '$d->{q[CLASS]} = $' . $pkg . '::METACLASS;'
        . 'local $::CLASS = $d->{q[CLASS]};'
    ;

    $self->inject_if_block( $inject );

    $self->shadow(sub (&@) {
        my $body = shift;
        my $data = {};

        $body->( $data );

        my $class = $data->{'CLASS'};
        $class->FINALIZE;

        return;
    });

    return;
}

sub build_class {
    shift;
    my %metadata = @_;

    my $class_Class = 'mop::class';
    if ( exists $metadata{ 'metaclass' } ) {
        $class_Class = delete $metadata{ 'metaclass' };
    }

    if ( exists $metadata{ 'extends' } ) {
        $metadata{ 'superclass' } = delete $metadata{ 'extends' };
    } else {
        $metadata{ 'superclass' } = 'mop::object';
    }

    if ( exists $metadata{ 'does' } ) {
        my $roles = delete $metadata{ 'does' };
        %{$metadata{ 'roles' }} = map {
            if (ref) {
                $_->name => $_;
            }
            else {
                $_ => mop::util::find_meta($_);
            }
        } (ref($roles) eq q(ARRAY) ? @$roles : $roles);
    }

    my $class = $class_Class->new(%metadata);    

    $class->add_submethod(
        $class->method_class->new(
            name => 'metaclass',
            body => sub { $class }
        )
    );

    $class;
}

sub build_role {
    shift;
    my %metadata = @_;

    my $role_Class = 'mop::role';
    if ( exists $metadata{ 'metaclass' } ) {
        $role_Class = delete $metadata{ 'metaclass' };
    }

    my $role = $role_Class->new(%metadata);    

    $role->add_submethod(
        $role->method_class->new(
            name => 'metaclass',
            body => sub { $role }
        )
    );

    $role;
}

sub generic_method_parser {
    my $self     = shift;
    my $callback = shift;

    $self->init( @_ );

    $self->skip_declarator;

    my $name   = $self->strip_name;
    my $proto  = $self->strip_proto;
    my $inject = $self->scope_injector_call;
    if ($proto) {
        $inject .= 'my ($self, ' . $proto . ') = @_;';    
    }
    else {
        $inject .= 'my ($self) = @_;';
    }

    # create a $class variable, which
    # actually points to the class name
    # and not the metaclass object
    $inject .= 'my $class = $' . $CURRENT_CLASS_NAME{$self} . '::METACLASS->name;';

    # localize $::SELF here too 
    $inject .= 'local $::SELF = $self;';
    
    # and localize the $::CLASS here
    $inject .= 'local $::CLASS = $' . $CURRENT_CLASS_NAME{$self} . '::METACLASS;';

    # this is our method preamble, it
    # basically creates a method local
    # variable for each attribute, then 
    # it will cast the magic on it to 
    # make sure that any change in value
    # is stored in the fieldhash storage
    foreach my $attr (@{ $CURRENT_ATTRIBUTE_LIST{$self} }) {
        my $key_name = $self->_get_storage_name_for_attribute($attr);
        $inject .= 'my ' . $attr . ' = ${ $' . $key_name . '{$self} || \(undef) };'
                . 'Variable::Magic::cast(' 
                    . $attr . ', '
                    . '$' . __PACKAGE__ . '::WIZARD, '
                    . '[ mop::util::get_object_id($self), \%' . $key_name . ' ]' 
                . ');'
                ; 
    }
    
    $self->skipspace;
    my $linestr = $self->get_linestr;
    if (substr($linestr, $self->offset, 1) ne '{')
    {
        substr($linestr, $self->offset, 0) =
            "{ return; }" .
            __PACKAGE__."->required_method_parser(q[$name]);";
        $self->set_linestr($linestr);
        $self->inject_if_block( $inject );
        $self->shadow($callback->($name));
        return;
    }

    $self->inject_if_block( $inject );
    $self->shadow($callback->($name));

    return;
}

sub _get_storage_name_for_attribute {
    my ($self, $attr) = @_;
    my $key = substr( $attr, 1, length $attr );
    '__' . $key . '_STORAGE'
}

sub method_parser {
    my $self = shift;
    $self->generic_method_parser(sub {
        my $name = shift;
        return sub (&) {
            my ($body, %opts) = @_;
            $::CLASS->add_method(
                $::CLASS->method_class->new(
                    name => $name,
                    body => Sub::Name::subname( $name, $body )
                )
            )
        }
    }, @_);
}

sub submethod_parser {
    my $self = shift;
    $self->generic_method_parser(sub {
        my $name = shift;
        return sub (&) {
            my $body = shift;
            $::CLASS->add_submethod(
                $::CLASS->submethod_class->new(
                    name => $name,
                    body => Sub::Name::subname( $name, $body )
                )
            )
        }
    }, @_);
}

sub required_method_parser {
    my $self = shift;
    my ($name) = @_;
    
    delete($::CLASS->methods->{$name});
    $::CLASS->add_required_method($name);
}

sub attribute_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;
    $self->skipspace;

    my $name;

    my $linestr = $self->get_linestr;
    if ( substr( $linestr, $self->offset, 1 ) eq '$' ) {
        my $length = Devel::Declare::toke_scan_ident( $self->offset );
        $name = substr( $linestr, $self->offset, $length );

        my $full_length = $length;
        my $old_offset  = $self->offset;

        $self->inc_offset( $length );
        $self->skipspace;

        my $proto;
        if ( substr( $linestr, $self->offset, 1 ) eq '(' ) {
            my $length = Devel::Declare::toke_scan_str( $self->offset );
            $proto = Devel::Declare::get_lex_stuff();
            $full_length += $length;
            Devel::Declare::clear_lex_stuff();
            $self->inc_offset( $length );
        }

        $self->skipspace;
        if ( substr( $linestr, $self->offset, 1 ) eq '=' ) {
            $self->inc_offset( 1 );
            $self->skipspace;
            if ( substr( $linestr, $self->offset, 2 ) eq 'do' ) {
                substr( $linestr, $self->offset, 2 ) = 'sub';
            }
        }

        my $key_name  = $self->_get_storage_name_for_attribute($name);

        substr( $linestr, $old_offset, $full_length ) = '(mop::util::init_attribute_storage(my %' . $key_name . ')' . ( $proto ? (', (' . $proto) : '') . ')';

        $self->set_linestr( $linestr );
        $self->inc_offset( $full_length );
    }

    push @{ $CURRENT_ATTRIBUTE_LIST{$self} } => $name; 

    $self->shadow(sub ($@) : lvalue {
        my ($storage, %metadata) = @_;
        my $initial_value;
        $::CLASS->add_attribute(
            $::CLASS->attribute_class->new(
                name    => $name,
                default => \$initial_value,
                storage => $storage, 
                %metadata
            )
        );
        $initial_value
    });

    return;
}

sub inject_scope {
    my $class  = shift;
    my $inject = shift || ';';
    on_scope_end {
        my $linestr = Devel::Declare::get_linestr;
        return unless defined $linestr;
        my $offset  = Devel::Declare::get_linestr_offset;
        if ( $inject eq ';' ) {
            substr( $linestr, $offset, 0 ) = $inject;
        }
        else {
            substr( $linestr, $offset - 1, 0 ) = $inject;
        }
        Devel::Declare::set_linestr($linestr);
    };
}

1;

__END__

