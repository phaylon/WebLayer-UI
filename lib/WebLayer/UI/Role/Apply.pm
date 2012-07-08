package WebLayer::UI::Role::Apply;
use Moo::Role;
use Carp        qw( confess );
use namespace::clean;

my $_apply = sub {
    my ($self, $code, @args) = @_;
    local $_ = $self;
    $code->(@args);
    return 1;
};

sub apply {
    my ($self, $code) = @_;
    $self->$_apply($code);
    return $self;
}

sub apply_if {
    my ($self, $value, $code) = @_;
    $self->$_apply($code, $value)
        if $value;
    return $self;
}

sub apply_ifdef {
    my ($self, $value, $code) = @_;
    $self->$_apply($code, $value)
        if defined $value;
    return $self;
}

sub apply_each {
    my ($self, $values, $code) = @_;
    confess q{Value passed to 'apply_each' has to be an array reference}
        unless ref $values eq 'ARRAY';
    $self->$_apply($code, $_)
        for @$values;
    return $self;
}

1;
