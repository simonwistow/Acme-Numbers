package Acme::Numbers;
use strict;
use Lingua::EN::Words2Nums qw(words2nums);
our $AUTOLOAD;
our $VERSION = '0.6';

sub import {
	my $class = shift;
    no strict 'refs';
    no warnings 'redefine';
    my ($pkg, $file) = caller; 
    foreach my $num ((keys %Lingua::EN::Words2Nums::nametosub, 'and', 'point', 'zero')) {
        *{"$pkg\::$num"} = sub { $class->$num };
    }
};


sub new {
    my $class = shift;
	$class = ref $class if ref $class;
    my $val   = shift;
	my $op    = shift;
    bless { value => $val, operator => $op }, $class;
}

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
		#print "Adding $val->{value} to $self->{value}\n";
		my ($num, $frac) = split /\./, $self->{value};
		#$frac ||= 0;
		if ((defined $frac && $frac>0 && $frac<10) || $val->value == 0 || (defined $frac && $frac =~ m!0$!)) {
			$frac .= $val->value;
		} else {
			$frac += $val->value;
		}
		#print "Got ${num}.${frac}\n";
		return $self->new("${num}.${frac}", 'point');
	} 
}

sub recall {
    my ($self, $new) = @_;
    my $class = shift;
    if (ref($new) && $new->isa(__PACKAGE__)) {
        return $self->handle($new);
    } else {
        return $self->value.$new;
    } 
}

use overload '""' => 'value',
             '.'  => "recall";


sub DESTROY {}

1;
