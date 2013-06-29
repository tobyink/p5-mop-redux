=pod

=encoding utf8

=head1 PURPOSE

This test checks how C<< class { ... } >> behaves within control structures.

=cut

use strict;
use warnings;
use Test::More;
use mop;

diag <<'_';

****
**** I don't know whether any of this behaviour is intentional!
****
_

for my $iteration (1, 2)
{
	class Class1 {
		has $n = $iteration;
		method n { $n };
	}
}

my $instance1 = Class1->new;
is($instance1->n, 2);

my $x = 2;
if ($x > 1)
{
	class Class2 { }
}
else
{
	class Class3 { }
}

ok('Class2'->can('new'));
ok(not 'Class3'->can('new'));

done_testing;
