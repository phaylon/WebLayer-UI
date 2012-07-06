package WebLayer::UI::Effect::Hide;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Effect';

sub _render {
    my ($self) = @_;
    return sprintf q!$(%s).hide(%s)!,
        $self->_render_selectors,
        join ', ',
        $self->_has_duration ? $self->_render_duration : (),
        $self->_has_continue ? $self->_render_continue : ();
}

1;
