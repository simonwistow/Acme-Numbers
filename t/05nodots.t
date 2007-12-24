#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Scalar::Util qw(set_prototype);

###############################################
# playing with prototypes

sub deux {
  local $^W = 0;
  return "2".shift;
}
set_prototype(\&deux, ';$');

sub mille (;$) {
  local $^W = 0;
  return "000".shift;
}
set_prototype(\&mille, ';$');

is((deux mille), "2000");

###############################################
# Same thing in Acme::Numbers

use Acme::Numbers;

is(two.thousand , "2000");
is(two(thousand), "2000");
is((two thousand), "2000");

################################
# todo tests (aka, this doesn't work)

TODO: {
   local $TODO = "Haven't figured out how to do this yet";
   
   # gah, "and" means completely the wrong thing here
   # we could overload it, but in this case it wouldn't help
   # as the precidence is all wrong
   my $foo = two thousand and eight;  # NEW YEAR! WHOOO
   is($foo, "2008", "and means something else");

   # gah, we (of course) think that the comma is for us
   # not the surrounding function call (i.e. the comma
   # is bound to "one" not to "fred")
   sub fred ($$) {}
   eval q{
     fred(one two, "placeholder")
   };
   ok(!$@, "problems with psudo-calls") or diag ($@);
};
