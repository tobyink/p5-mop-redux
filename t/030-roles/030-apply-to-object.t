#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

role Foo {
    method foo { "foo" }
}

role Bar {
    method bar { "bar" }
}

class Gorch with Foo {
    method gorch { "gorch" }
}

sub does_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($thing, @roles) = @_;
    subtest "$thing does qw(@roles)" => sub {
        ok($thing->DOES($_), "$thing DOES $_") for @roles;
        done_testing;
    };
}

my $obj = Gorch->new;
my $obj2 = Gorch->new;
isa_ok($obj, "Gorch");
can_ok($obj, qw/ foo gorch /);
does_ok($obj, qw/ Foo Gorch /);

my $r = mop::get_meta("Bar")->apply_to_object($obj);

diag explain($r);

is($r, $obj);
isa_ok($obj, "Gorch");
can_ok($obj, qw/ foo bar gorch /);
does_ok($obj, qw/ Foo Bar Gorch /);

ok(not $obj2->isa(ref $obj));
ok(not $obj2->can("bar"));
ok(not $obj2->DOES("Bar"));

done_testing;