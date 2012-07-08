package WebLayer::UI::Component::Paragraph;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->classes('ui-paragraph')
         ->element('p');
}

1;
