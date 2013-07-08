use strict;
use warnings;
use mop;

my $i;

sub mopx::compose {
	my ($base, @roles) = @_;
	my $classname = sprintf('mopx::compose::__ANON__::%04d', ++$i);
	
	'mop::class'->new(
		name       => $classname,
		superclass => $base,
		roles      => \@roles,
	);
	
	return $classname;
}

1;
