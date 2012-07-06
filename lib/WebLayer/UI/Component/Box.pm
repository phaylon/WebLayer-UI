package WebLayer::UI::Component::Box;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _default_template { 'box.html' }

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_common('.ui-box'))
        ->append_content('.ui-box', $self->_render_children($ctx))
        ->memoize;
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithChildren
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
