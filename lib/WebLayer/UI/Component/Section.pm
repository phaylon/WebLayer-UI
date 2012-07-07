package WebLayer::UI::Component::Section;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->classes('ui-section')
         ->element('section');
}

1;
