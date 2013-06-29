=pod

=encoding utf8

=head1 PURPOSE

This test checks that C<< class { ... } >> is a lexical scope.

=cut

use strict;
use warnings;
use Test::More;
use mop;

no strict "refs";

my $name = "xyz";
sub xyz { 999 };

class XYZ {
	use strict "refs";
	my $name = "abc";
}

is($name, "xyz", 'lexically scoped variable do not leak');
is(&$name, 999, 'lexically scoped pragmata do not leak');

done_testing;
