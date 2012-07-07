package WebLayer::UI::Component::Role::WithEvents::Inputs;
use Moo::Role;
use namespace::clean;

around _has_events => sub {
    my ($orig, $self) = @_;
    change => {},
    $self->$orig,
};

1;
