package WebLayer::UI::Component::Segment;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->classes('ui-segment')
         ->element('span');
}

1;
