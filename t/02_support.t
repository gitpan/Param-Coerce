#!/usr/bin/perl -w

# Support method testing for Param::Coerce

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

use Test::More tests => 25;
use Param::Coerce ();





#####################################################################
# Begin testing support methods

# Test _method
is( Param::Coerce::_method(),           '',    '_method() returns correctly' );
is( Param::Coerce::_method(undef),      '',    '_method(undef) returns correctly' );
is( Param::Coerce::_method(1),          '',    '_method(1) returns correctly' );
is( Param::Coerce::_method([]),         '',    '_method([]) returns correctly' );
is( Param::Coerce::_method(' '),        '',    '_method(" ") returns correctly' );
is( Param::Coerce::_method('foo'),      'foo', '_method("foo") returns correctly' );
is( Param::Coerce::_method('foo::bar'), '',    '_method("foo::bar") returns correctly' );
is( Param::Coerce::_method('1asdf'),    '',    '_method("1asdf") return correctly' );

# Test _class
is( Param::Coerce::_class(),           '',          '_class() returns correctly' );
is( Param::Coerce::_class(undef),      '',          '_class(undef) returns correctly' );
is( Param::Coerce::_class(1),          '',          '_class(1) returns correctly' );
is( Param::Coerce::_class([]),         '',          '_class([]) returns correctly' );
is( Param::Coerce::_class(' '),        '',          '_class(" ") returns correctly' );
is( Param::Coerce::_class('foo'),      'foo',       '_class("foo") returns correctly' );
is( Param::Coerce::_class('foo::bar'), 'foo::bar',  '_class("foo::bar") returns correctly' );
is( Param::Coerce::_class('1asdf'),    '',          '_class("1asdf") return correctly' );
is( Param::Coerce::_class('::'),       'main',      '_class("::") returns correctly' );
is( Param::Coerce::_class('::bar'),    'main::bar', '_class("::bar") returns correctly' );

# Test _coercion method
is( Param::Coerce::_coercion_method('Foo'), '__as_Foo', '_coercion_method("Foo") returns correctly' );
is( Param::Coerce::_coercion_method('Foo::Bar'), '__as_Foo_Bar', '_coercion_method() returns correctly' );

# Test _loaded
ok(   Param::Coerce::_loaded('Param::Coerce'), '_loaded returns true for Param::Coerce' );
ok( ! Param::Coerce::_loaded('Param::Coerce::Bad'), '_loaded returns false for Param::Coerce::Bad' );

# Test _function_exists
ok(   Param::Coerce::_function_exists('Param::Coerce', '_function_exists'), '_function_exists sees itself' );
ok( ! Param::Coerce::_function_exists('Foo', 'bar'), '_function_exists doesn\' see non-existant function' );
ok( ! Param::Coerce::_function_exists('Param::Coerce', 'VERSION'),
	'_function_exists does not return true for other variable types' );

exit(0);
