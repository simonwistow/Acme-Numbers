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
    print forty.two."\n";                 # print 42
    print six.hundred.and.sixty.six."\n"; # prints 666
    print one.million."\n";               # print 1000000

    print three.point.one.four."\n";      # print 3.14
    print one.point.zero.two."\n";        # print 1.02
    print zero.point.zero.five."\n";      # print 0.05

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
    foreach my $num ((keys %Lingua::EN::Words2Nums::nametosub, 'and', 'point', 'zero')) {
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
    return $self->{value} + 0;
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method    =~ s/.*://;   # strip fully-qualified portion
    my $val;
    if ($method eq 'and' || $method eq 'point') {
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
    if ($self->{operator} ne 'point') {
        if ($val->{operator} eq 'point') {
            $self->{operator} = 'point';
            return $self;
        } else {
            my $val = $val->value;
            if ($self->value < $val && $self->{operator} ne 'add') {
                $val *= $self->value;
            } else {
                $val += $self->value;
               }
            return $self->new($val, 'num');
        }
    } else { # point
        # first get the fractional part
        my ($num, $frac) = split /\./, $self->{value};
        #$frac ||= 0;
        if ((defined $frac && $frac>0 && $frac<10) || $val->value == 0 || (defined $frac && $frac =~ m!0$!)) {
            $frac .= $val->value;
        } else {
            $frac += $val->value;
        }
        return $self->new("${num}.${frac}", 'point');
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
