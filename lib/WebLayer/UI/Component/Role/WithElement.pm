package WebLayer::UI::Component::Role::WithElement;
use Moo::Role;
use namespace::clean;

has _element => (is => 'rw');

sub element { $_[0]->_element($_[1]); shift }

sub _element_or_default {
    my ($self, $default) = @_;
    my $element = $self->_element;
    return $element
        if defined $element;
    return $default;
}

1;
