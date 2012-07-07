package WebLayer::UI::Component::Footer;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->classes('ui-footer')
         ->element('footer');
}

1;

