#!/usr/bin/perl -w

# Using Param::Coerce the correct way, and "does stuff happen" tests

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

use Test::More tests => 22;
use Param::Coerce;

BEGIN { $DB::single = $DB::single = 1 }




#####################################################################
# Did various things get created

ok( Param::Coerce::_function_exists('Foo::Bar::Usage2', 'coerce'), "use Param::Coerce 'coerce'; # Imported something" );
ok( Param::Coerce::_function_exists('Foo::Bar::Usage3', '_Bar'), "use Param::Coerce '_Bar' => 'Bar'; # Created something" );





#####################################################################
# Test the usage of the various ways

{ # Usage 1
	my $Bar = Bar->new; isa_ok( $Bar, 'Bar' );
	my $Foo = Foo->new; isa_ok( $Foo, 'Foo' );
	my $Usage = Foo::Bar::Usage1->new( $Bar );
	isa_ok( $Usage, 'Foo::Bar::Usage1' );
	isa_ok( $Usage->{Bar}, 'Bar' );
	$Usage = Foo::Bar::Usage1->new( $Foo );
	isa_ok( $Usage, 'Foo::Bar::Usage1' );
	isa_ok( $Usage->{Bar}, 'Bar' );	
}

{ # Usage 2
	my $Bar = Bar->new; isa_ok( $Bar, 'Bar' );
	my $Foo = Foo->new; isa_ok( $Foo, 'Foo' );
	my $Usage = Foo::Bar::Usage2->new( $Bar );
	isa_ok( $Usage, 'Foo::Bar::Usage2' );
	isa_ok( $Usage->{Bar}, 'Bar' );
	$Usage = Foo::Bar::Usage2->new( $Foo );
	isa_ok( $Usage, 'Foo::Bar::Usage2' );
	isa_ok( $Usage->{Bar}, 'Bar' );	
}


{ # Usage 3
	my $Bar = Bar->new; isa_ok( $Bar, 'Bar' );
	my $Foo = Foo->new; isa_ok( $Foo, 'Foo' );
	my $Usage = Foo::Bar::Usage3->new( $Bar );
	isa_ok( $Usage, 'Foo::Bar::Usage3' );
	isa_ok( $Usage->{Bar}, 'Bar' );
	$Usage = Foo::Bar::Usage3->new( $Foo );
	isa_ok( $Usage, 'Foo::Bar::Usage3' );
	isa_ok( $Usage->{Bar}, 'Bar' );	
}

{ # __from coercion
	my $Bar = Bar->new; isa_ok( $Bar, 'Bar' );
	my $Foo = Param::Coerce::coerce 'Foo', $Bar;
	isa_ok( $Foo, 'Foo' );
}





#####################################################################
# Create all the testing packages we needed for this

package Bar;

sub new {
	bless { }, shift;
}

package Foo;

sub new {
	bless {}, shift;
}

sub __as_Bar   { Bar->new }
sub __from_Bar { Foo->new }

package Foo::Bar::Usage1;

use Param::Coerce;

sub new {
	my $class = shift;
	my $Bar = Param::Coerce::coerce 'Bar', shift or die 'Param::Coerce::coerce usage test failed';
	bless { Bar => $Bar }, $class;
}

package Foo::Bar::Usage2;

use Param::Coerce 'coerce';

sub new {
	my $class = shift;
	my $Bar = coerce 'Bar', shift or die 'Imported coerce usage test failed';
	bless { Bar => $Bar }, $class;
}

package Foo::Bar::Usage3;

use Param::Coerce '_Bar' => 'Bar';

sub new {
	my $class = shift;
	my $Bar = $class->_Bar(shift) or die 'Method usage test failed';
	bless { Bar => $Bar }, $class;
}

1;
