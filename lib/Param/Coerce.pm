package Param::Coerce;

=pod

=head1 NAME

Param::Coerce - Allows your classes to do coercion of parameters

=head1 SYNOPSIS

  # A class that can be coerced to a different class
  package My::Class;
  
  sub new {
      bless { value => $_[1] }, $_[0];
  }
  
  sub __as_Foo_Bar {
      my $self = shift;
      Foo::Bar->new( $self->{value} );
  }
  
  
  
  # Package taking a Foo::Bar parameter
  package My::Consumer;
  
  # ->new MUST be provided a Foo::Bar
  sub new {
      my $class = shift;
      my $param = Param::Coerce->param('Foo::Bar', shift) or die 'Not passed a Foo::Bar';
      
      bless {
          FooBar => $param,
          }, $class
  }
  
  
  
  # Import the same functionality locally
  package My::Thingy;
  
  use Param::Coerce '_FooBar' => 'Foo::Bar';
  
  sub new {
  	my $class = shift;
  	my $param = $class->_FooBar(shift) or die 'Not passed a Foo::Bar';
  	bless {
  	    FooBar => $param,
  		}, $class;
  }

=head1 DESCRIPTION

A big part of good API design, and a big part of Perl's general use of
subroutine parameters, is that we should be able to be flexibly in the
ways that we take parameters.

Param::Coerce attempts to encourage this, by making it easier to take a
variety of different things, and to do so without slowing your own code
down.

=head2 What is Coercion

"Coercion" in computing terms generally referse to "implicit type
conversion", and is most often seen in auto-boxing and auto-unboxing of
String objects in the Java language. Perl itself does coercion between
string, numerical and boolean contexts. The L<overload> pragma, and it's
string overloading is the form of coercion you are most likely to have
encountered in Perl programming.

Param::Coerce is intended for higher-order coercion of subroutine and
(mostly) method parameters, allowing coercion between different types of
objects.

=head2 __as_Object_Class Methods

At the heart of Param::Coerce is the ability to transform objects from one
thing to another. This can be done by a variety of different mechanisms.

The prefered mechanism for this is by creating a specially named method
in a class that indicates it can be coerced into another type of object.

That is, class Object::From provides an object method that returns an
equivalent Object::To object.

  package My::Class;
  
  # Coerce a My::Class object into a Foo::Bar object
  sub __as_Foo_Bar {
  	...
  }

=head2 Loading Classes

One thing to note with the C<__as_Class> methods is that you are B<not>
required to load the class you are converting to in the class you are
converting from.

In the above example, My::Class would B<not> have to load Foo::Bar, using
either C<use Foo::Bar> at the top of the module or C<require Foo::Bar> in
the method itself. The need to load the classes for every object we might
some day need to be converted to would result in highly excessive resource
usage.

Instead, Param::Coerce guatentees that the class you are converting to
C<will> be loaded before it calls the __as_Foo_Bar method. Of course, in
most situations you will have already loaded it for another purpose in
either the From or To classes and this won't be an issue.

If you make use of some class B<other than> the direct class being Coerced
to in the __as_Foo_Bar method, you will need to make sure that is loaded
in your code, but it is suggested that you do it ar run-time with a
C<require> if you are not using it elsewhere.

=head2 Coercing a Parameter

The most explicit way of accessing the coercion functionality is with the
Param::Coerce::coerce function. It takes as it's first argument the name
of the class you wish to coerce to, followed by the parameter you wish to
apply the coercion to.

  package My::Class;
  
  use URI ();
  use Param::Coerce '_URI' => 'URI';
  
  sub new {
  	my $class = shift;
  	
  	# Take a URI argument
  	my $URI = Param::Coerce::coerce('URI', shift) or return;
  	
  	...
  }

For people doing procedural programming, you may also import this function.

  # Import the coerce function
  use Param::Coerce 'coerce';

Please note thatThe C<coerce|Param::Coerce> function is the B<only> function
that can be imported, and that the two argument pragma (or the passing of
two or more arguments to ->import) means something different entirely.

=head2 Importing Parameter Coercion Methods

The second way of using Param::Coerce, and the more common one for
Object-Oriented programming, is to create method specifically for taking
parameters in a coercing manner.

  package My::Class;
  
  use URI ();
  use Param::Coerce '_URI' => 'URI';
  
  sub new {
  	my $class = shift;

	# Take a URI as parameter
  	my $URI = $class->_URI(shift) or return;
  	
  	...
  }

=head2 Chained Coercion

While it is intended that Param::Coerce will eventually support coercion
using multiple steps, like C<<Foo::Bar->__as_HTML_Location->__as_URI>>,
it is not currently capable of this. At this time only a single coercion
step is supported.

=head1 FUNCTIONS

=cut

use strict;
use UNIVERSAL 'isa', 'can';
use Scalar::Util 'blessed';
use Carp 'croak';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub import {
	my $class = shift;
	return unless @_; # Nothing to do
	die "Too many parameters" if @_ > 2; # Um, what?

	# We'll need to know who is calling us
	my $pkg = caller();

	# We export them the coerce function if they want it
	if ( @_ == 1 ) {
		croak "Param::Coerce does not export '$_[0]'" unless $_[0] eq 'coerce';
		no strict 'refs';
		*{"${pkg}::coerce"} = *coerce;
		return 1;
	}

	# The two argument form is 'method' => 'class'
	# Check the values given to us.
	my $method = _method($_[0])      or croak "Illegal method name '$_[0]'";
	my $want   = _class($_[1])       or croak "Illegal class name '$_[1]'";
	_function_exists($pkg, $method) and croak "Cannot create '${pkg}::$method'. It already exists";
	_loaded($want)                   or croak "Cannot create coercion method for unloaded class '$want'";

	# Create the method in our caller
	eval "package $pkg; sub $method { Param::Coerce::_coerce('$want', \$_[1]) }";
	croak "Failed to create coercion method '$method' in $pkg': $@" if $@;

	1;
}

=pod

=head2 coerce $class, $param

The C<coerce> function takes a class name and a single parameter and
attempts to coerce the parameter into the intended class, or one of it's
subclasses.

Please note that it is the responsibility of the consuming class to ensure
that the class you wish to coerce to is loaded. C<coerce> will check this
and die is it is not loaded.

Returns an instance of the class you specify, or one of it's subclasses.
Returns C<undef> if the parameter cannot be coerced into the class you wish.

=cut

sub coerce($$) {
	# Check what they want properly first
	my $want = _class($_[0]) or croak "Illegal class name '$_[0]'";
	_loaded($want) or croak "Tried to coerce to unloaded class '$want'";

	# Now call the real function
	_coerce($want, $_[1]);
}

# Internal version with less checks. Should ONLY be called once
# the first argument is FULLY validated.
sub _coerce {
	my $want = shift;
	my $have = blessed $_[0] ? shift : return undef;

	# In the simplest case it is already what we need
	return $have if $have->isa($want);

	# Does what we have support casting to what we want?
	my $method = _coercion_method($want);
	if ( $have->can($method) ) {
		$have = $have->$method();
		if ( blessed $have and $have->isa($want) ) {
			return $have;
		}
	}

	# Couldn't cast to $want or casting failed
	undef;
}





#####################################################################
# Support Functions

# Validate a method
sub _method {
	my $name = (defined $_[0] and ! ref $_[0]) ? shift : return '';
	$name =~ /^[^\W\d]\w*$/ ? $name : '';
}

# Validate a class name.
sub _class {
	my $name = (defined $_[0] and ! ref $_[0]) ? shift : return '';
	return 'main' if $name eq '::';
	$name =~ s/^::/main::/;
	$name =~ /\A[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*\z/ ? $name : '';
}

# Derive the coercion name for a given class
sub _coercion_method {
	my $name = shift;
	$name =~ s/(?:\'|::)/_/g;
	"__as_$name";
}

# Is a class loaded.
sub _loaded {
	no strict 'refs';
	foreach ( keys %{"$_[0]::"} ) {
		return 1 unless substr($_, -2, 2) eq '::';
	}
	'';
}

# Does a function exist.
sub _function_exists {
	no strict 'refs';
	defined &{"$_[0]::$_[1]"};
}

1;

=pod

=head1 TO DO

- Write the unit tests

- Implement chained coercion

- Provide a way to coerce to string, int, etc that is compatible with
L<overload> and other types of things.

=head1 SUPPORT

Module not implemented, there's nothing to be broken. But if you have
installation problems, submit them to the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Param%3A%3ACoerce>

For other issues, contact the designer

=head1 AUTHORS

Adam Kennedy (Maintainer), L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
