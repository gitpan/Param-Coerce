package Param::Coerce;

=pod

=head1 NAME

Param::Coerce - Allows your classes to do coercion of parameters

=head1 SYNOPSIS

This example demonstrates a real world example, using the L<HTML::Location>
module, which has been enabled for use with it.

  # My class needs a URI
  package Web::Spider;
  
  use URI;
  use Param::Coerce 'coerce';
  
  sub new {
      my $class = shift;
      
      # Where do we start spidering
      my $start = coerce('URI', shift) or die "Wasn't passed a URI";
      
      bless { root => $start }, $class;
  }
  
  #############################################
  # Now we can do the following
  
  # Pass a URI as normal
  my $URI     = URI->new('http://ali.as/');
  my $Spider1 = Web::Spider->new( $URI );
  
  # We can also pass anything that can be coerced into being a URI
  my $Website = HTML::Location->new( '/home/adam/public_html', 'http://ali.as' );
  my $Spider2 = Web::Spider->new( $Website );

=head1 DESCRIPTION

A big part of good API design is that we should be able to be flexible in
the ways that we take parameters.

Param::Coerce attempts to encourage this, by making it easier to take a
variety of different arguments, while adding negligable additional complexity
to your code.

=head2 What is Coercion

"Coercion" in computing terms generally referse to "implicit type
conversion". This is where data and object are converted from one type to
another behind the scenes, and you just just magically get what you need.

The L<overload> pragma, and its string overloading is the form of coercion
you are most likely to have encountered in Perl programming. In this case,
your object is automatically (within perl itself) coerced into a string.

Param::Coerce is intended for higher-order coercion between various types of
different objects, for use mainly in subroutine and (mostly) method
parameters, particularly on external APIs.

=head2 __as_Another_Class Methods

At the heart of Param::Coerce is the ability to transform objects from one
thing to another. This can be done by a variety of different mechanisms.

The prefered mechanism for this is by creating a specially named method
in a class that indicates it can be coerced into another type of object.

As an example, L<HTML::Location> provides an object method that returns an
equivalent URI object.

  # In the package HTML::Location
  
  # Coerce to a URI
  sub __as_URI {
  	my $self = shift;
 	return URI->new( $self->uri );
  }

=head2 __from_Another_Class Methods

From version 0.04 of Param::Coerce, you may now also provide
__from_Another_Class methods as well. In the above example, rather then
having to define a method in HTML::Location, you may instead define one in
URI. The following code has an identical effect.

  # In the package URI
  
  # Coerce from a HTML::Location
  sub __from_HTML_Location {
  	my $Location = shift;
  	return URI->new( $Location->uri );
  }

Param::Coerce will only look for the __from method, if it does not find a __as
method.

=head2 Loading Classes

One thing to note with the C<__as_Another_Class> methods is that you are
 B<not> required to load the class you are converting to in the class you are
converting from.

In the above example, HTML::Location does B<not> have to load the URI class.
The need to load the classes for every object we might some day need to be
coerced to would result in highly excessive resource usage.

Instead, Param::Coerce guarentees that the class you are converting to
C<will> be loaded before it calls the __as_Another_Class method. Of course,
in most situations you will have already loaded it for another purpose in
either the From or To classes and this won't be an issue.

If you make use of some class B<other than> the class you are being coerced
to in the __as_Another_Class method, you will need to make sure that is loaded
in your code, but it is suggested that you do it at run-time with a
C<require> if you are not using it already elsewhere.

=head2 Coercing a Parameter

The most explicit way of accessing the coercion functionality is with the
Param::Coerce::coerce function. It takes as its first argument the name
of the class you wish to coerce B<to>, followed by the parameter to which you
wish to apply the coercion.

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
use Carp         ();
use Scalar::Util ();

# Load Overhead: 52k

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}

# The method hint cache
my %methods = ();





#####################################################################
# Use as a Pragma

sub import {
	my $class = shift;
	return unless @_; # Nothing to do
	die "Too many parameters" if @_ > 2; # Um, what?

	# We'll need to know who is calling us
	my $pkg = caller();

	# We export them the coerce function if they want it
	if ( @_ == 1 ) {
		Carp::croak "Param::Coerce does not export '$_[0]'" unless $_[0] eq 'coerce';
		no strict 'refs';
		*{"${pkg}::coerce"} = *coerce;
		return 1;
	}

	# The two argument form is 'method' => 'class'
	# Check the values given to us.
	my $method = _method($_[0])      or Carp::croak "Illegal method name '$_[0]'";
	my $want   = _class($_[1])       or Carp::croak "Illegal class name '$_[1]'";
	_function_exists($pkg, $method) and Carp::croak "Cannot create '${pkg}::$method'. It already exists";
	_loaded($want)                   or Carp::croak "Cannot create coercion method for unloaded class '$want'";

	# Create the method in our caller
	eval "package $pkg; sub $method { Param::Coerce::_coerce('$want', \$_[1]) }";
	Carp::croak "Failed to create coercion method '$method' in $pkg': $@" if $@;

	1;
}

=pod

=head2 coerce $class, $param

The C<coerce> function takes a class name and a single parameter and
attempts to coerce the parameter into the intended class, or one of its
subclasses.

Please note that it is the responsibility of the consuming class to ensure
that the class you wish to coerce to is loaded. C<coerce> will check this
and die is it is not loaded.

Returns an instance of the class you specify, or one of its subclasses.
Returns C<undef> if the parameter cannot be coerced into the class you wish.

=cut

sub coerce($$) {
	# Check what they want properly first
	my $want = _class($_[0]) or Carp::croak "Illegal class name '$_[0]'";
	_loaded($want) or Carp::croak "Tried to coerce to unloaded class '$want'";

	# Now call the real function
	_coerce($want, $_[1]);
}

# Internal version with less checks. Should ONLY be called once
# the first argument is FULLY validated.
sub _coerce {
	my $want = shift;
	my $have = Scalar::Util::blessed $_[0] ? shift : return undef;

	# In the simplest case it is already what we need
	return $have if $have->isa($want);

	# Is there a coercion hint for this combination
	my $key = ref($have) . ',' . $want;
	my $method = exists $methods{$key} ? $methods{$key}
		: _resolve($want, ref($have), $key)
		or return undef;

	# Call the coercion method
	$have = ($method =~ s/^-//) ? $want->$method($have) : $have->$method();
	(Scalar::Util::blessed $have and $have->isa($want)) ? $have : undef
}

# Try to work out how to get from one class to the other class
sub _resolve {
	my ($want, $have, $key) = @_;

	# Look for a __as method
	my $method = "__as_$want";
	$method =~ s/::/_/g;
	return $methods{$key} = $method if $have->can($method);

	# Look for a direct __from method
	$method = "__from_$have";
	$method =~ s/::/_/g;
	return $methods{$key} = "-$method" if $want->can($method);

	# Give up (and don't try again)
	$methods{$key} = '';
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

- Write more unit tests

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
