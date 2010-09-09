#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DNS::DNR' );
}

diag( "Testing DNSR::DNR $DNS::DNR::VERSION, Perl $], $^X" );
