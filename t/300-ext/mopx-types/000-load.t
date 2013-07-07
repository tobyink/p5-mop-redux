#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/ext/mopx-types';

BEGIN {
    use_ok( 'mopx::types' );
}

done_testing;
