use inc::Module::Install;

name          ( 'Param-Coerce');
abstract      ( 'Allows your classes to do coercion of parameters');
author        ( 'Adam Kennedy<cpan@ali.as>');
version_from  ( 'lib/Param/Coerce.pm');
license       ( 'perl');

requires      ( 'perl'             => '5.005' );
requires      ( 'Carp'             => '0'     );
requires      ( 'Scalar::Util'     => '1.11'  );

build_requires( 'Test::More'       => '0.47'  );
build_requires( 'File::Spec'       => '0.82'  );

auto_install();

&WriteAll;
