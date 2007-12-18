package Acme::Numbers;
use strict;
use Lingua::EN::Words2Nums qw(words2nums);
our $AUTOLOAD;

# TODO
# Allow 'point' as in
#     one.point.five
# This will probably require switching back to
# A hashref for the object with 'value' and 'is_num'
# fields and then having extra smarts in handle()

sub import {
    no strict 'refs';
    no warnings 'redefine';
    my ($pkg, $file) = caller; 
    foreach my $num ((keys %Lingua::EN::Words2Nums::nametosub, 'and')) {
        *{"$pkg\::$num"} = sub { Numbers->$num };
    }
};


sub new {
    my $class = shift;
    my $val   = shift;
    bless \$val, $class;
}

sub value { 
    my $self = shift;
    return $$self;
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method    =~ s/.*://;   # strip fully-qualified portion
    my $val;
    if ($method eq 'and') {
        $val = 0;
    } else {
        $val = words2nums($method);
    }    
	return unless defined $val;
    return $self->handle($val);
}

sub handle {
    my ($self, $val) = @_;
    if (ref $self) {
        if ($self->value < $val) {
            $val *= $self->value;
        } else {
            $val += $self->value;
        }
    }
    return Numbers->new($val);

}

sub recall {
    my ($self, $new) = @_;
    if (ref($new) && $new->isa('Numbers')) {
        return $self->handle($new->value);
    } else {
        return $self->value.$new;
    } 
}

use overload '""' => 'value',
             '.'  => "recall";


sub DESTROY {}

1;
