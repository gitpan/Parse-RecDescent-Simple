#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::RecDescent::Simple' ) || print "Bail out!
";
}

diag( "Testing Parse::RecDescent::Simple $Parse::RecDescent::Simple::VERSION, Perl $], $^X" );
