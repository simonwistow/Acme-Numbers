#!perl -w

use Test::More tests => 8;
use Acme::Numbers;

is(four.pounds,            "4.00", "No pence");
is(four.pounds.fifty,      "4.50", "Trailing zero");
is(four.pounds.five,       "4.05", "Leading zero");
is(four.pounds.fifty.five, "4.55", "No zero");

is(four.pound,            "4.00", "No pence (no 's')");
is(four.pound.fifty,      "4.50", "Trailing zero (no 's')");
is(four.pound.five,       "4.05", "Leading zero (no 's')");
is(four.pound.fifty.five, "4.55", "No zero  (no 's')");

# TODO allow
# fifty.five.pence                 => 0.55
# four.pounds.fifty.five.pence     => 4.55
# four.pounds.and.fifty.five.pence => 4.55
