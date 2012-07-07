package WebLayer::UI::Component::Header;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->classes('ui-header')
         ->element('header');
}

1;
