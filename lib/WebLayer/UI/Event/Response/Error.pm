package WebLayer::UI::Event::Response::Error;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Event';

sub _render_func {
    my ($self) = @_;
    return sprintf q!function (xhr, text_status, exception) { %s }!, join ';',
        $self->_render_actions;
}

1;
