use strict;
use warnings;
use mop;

my $i;

sub mopx::compose {
	my ($base, @roles) = @_;
	my $classname = sprintf('mopx::compose::__ANON__::%04d', ++$i);
	
	no strict 'refs';
	${"$classname\::METACLASS"} = 'mop::class'->new(
		name       => $classname,
		superclass => ( ref($base) ? $base->name : $base ),
		roles      => [ map { ref($_) ? $_ : mop::get_meta($_) } @roles ],
	);
	
	${"$classname\::METACLASS"}->FINALIZE;
	
	require mro;
	mro::set_mro($classname, 'mop');
	
	return $classname;
}

1;
