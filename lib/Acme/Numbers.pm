package Acme::Numbers;
use strict;
use Lingua::EN::Words2Nums qw(words2nums);
our $AUTOLOAD;
our $VERSION = '0.6';


=head1 NAME

Acme::Numbers - a fluent numeric interface

=head1 SYNOPSIS

    use Acme::Numbers;

    print one."\n";                       # prints 1
    print two.hundred."\n";               # prints 200
    print forty.two."\n";                 # prints 42
    print six.hundred.and.sixty.six."\n"; # prints 666
    print one.million."\n";               # prints 1000000

    print three.point.one.four."\n";      # prints 3.14
    print one.point.zero.two."\n";        # prints 1.02
    print zero.point.zero.five."\n";      # prints 0.05

    print four.pounds."\n";               # prints "4.00"
    print four.pounds.five."\n";          # prints "4.05"
    print four.pounds.fifty."\n";         # prints "4.50"
    print four.pounds.fifty.five."\n";    # prints "4.55"

    print fifty.pence."\n";               # prints "0.50"
    print fifty.five.pence."\n";          # prints "0.55"
    print four.pounds.fifty.pence."\n";   # prints "4.55"
    print four.pounds.and.fifty.p."\n";   # prints "4.50"

    print fifty.cents."\n";               # prints "0.50"
    print fifty.five.cents."\n";          # prints "0.55"
    print four.dollars.fifty.cents."\n";  # prints "4.55"

    

=head1 DESCRIPTION

Inspired by this post

http://beautifulcode.oreillynet.com/2007/12/the_cardinality_of_a_fluent_in.php

and a burning curiosity. At leats, I hope the burning 
was curiosity.

=head1 ONE BIIIIIIIIIIIILLION

By default billion is 10**12 because, dammit, that's right.

If you want it to be an American billion then do

    use Acme::Numbers billion => 10**9;

Setting this automatically changes all the larger numbers 
(trillion, quadrillion, etc) to match.

=head1 METHODS

You should never really use these methods on the class directly.

All numbers handled by C<Lingua::EN::Words2Nums> are handled by this module.

In addition ...

=cut

sub import {
    my $class = shift;
    my %opts  = @_;

    $opts{billion} = 10**12 unless defined $opts{billion};
    no strict 'refs';
    no warnings 'redefine';
    my ($pkg, $file) = caller; 
    $Lingua::EN::Words2Nums::billion = $opts{billion};
    foreach my $num ((keys %Lingua::EN::Words2Nums::nametosub, 
                      'and', 'point', 'zero', 
                      'pound', 'pounds', 'pence', 'p',
                      'dollars', 'cents')) {
        *{"$pkg\::$num"} = sub { $class->$num };
    }
};



=head2 new <value> <operator>

C<operator> can be 'num', 'and' or 'point'

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $val   = shift;
    my $op    = shift;
    bless { value => $val, operator => $op }, $class;
}

=head2 value

The current numeric value

=cut

sub value { 
    my $self = shift;
    my $val = $self->{value} + 0;
    if ($self->{operator} =~ m!^p(ence)?$!) {
        $self->{last_added} = $val;
        $val = $val/100;
        $self->{operator} = 'pounds';
    }
    if ($self->{operator} =~ m!^pounds?$!) {
        my ($num, $frac) = split /\./, $val;
        $frac ||= 0;
        $frac = $self->{last_added} if defined $self->{last_added} && $self->{last_added}>$frac;
        $val  = sprintf("%d.%02d",$num,$frac);
    } 

    return $val;
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method    =~ s/.*://;   # strip fully-qualified portion
    my $val;
    $method = 'pounds' if $method eq 'dollars';
    $method = 'pence'  if $method eq 'cents';

    if ($method eq 'and' || $method =~ m!^p!) {
        $val = $self->new(0, $method) 
    } else {
        my $tmp = ($method eq 'zero')? 0 : words2nums($method);
        return unless defined $tmp;
        $val = $self->new($tmp, 'num');
    }
    if (ref $self) {
        return $self->handle($val);
    } else {
        return $val;
    }
}

=head2 handle <Acme::Numbers>

Handle putting these two objects together

=cut

sub handle {
    my ($self, $val) = @_;
    if ($self->{operator} !~ m!^p!) {
        if ($val->{operator} =~ m!^p!) {
            $self->{operator} = $val->{operator} unless $self->{operator} =~ m!^pounds?$!;
            return $self;
        } else {
            my $val = $val->{value};
            if ($self->value < $val && $self->{operator} ne 'add') {
                $val *= $self->{value};
            } else {
                $val += $self->{value};
            }
            return $self->new($val, 'num');
        }
    } else { # point
        # first get the fractional part
        my ($num, $frac) = split /\./, $self->{value};
        #$frac ||= 0;
        if ((defined $frac && $frac>0 && $frac<10) || $val->value == 0 || (defined $self->{last_added} and $self->{last_added} eq '0')) {
            $frac .= $val->{value};
        } else {
            $frac += $val->{value};
        }
        my $new = $self->new("${num}.${frac}", $self->{operator});
        $new->{last_added} = $val->{value};
        return $new;
    } 
}

=head2 concat <value>

Concatenate two things.

=cut

sub concat {
    my ($self, $new) = @_;
    my $class = shift;
    if (ref($new) && $new->isa(__PACKAGE__)) {
        return $self->handle($new);
    } else {
        return $self->value.$new;
    } 
}

use overload '""' => 'value',
             '.'  => 'concat';


sub DESTROY {}

1;
