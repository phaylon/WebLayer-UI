package WebLayer::UI::Component::Form;
use Moo;
use WebLayer::UI::Util  qw( :js );
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _default_template { 'form.html' }

sub _has_slots {
    submit_to => {
        set => sub { js_set_attr($_[0]->_sel_js_form, 'action', 'value') },
        get => sub { js_get_attr($_[0]->_sel_js_form, 'action') },
    },
    submit_method => {
        set => sub { js_set_attr($_[0]->_sel_js_form, 'method', 'value') },
        get => sub { js_get_attr($_[0]->_sel_js_form, 'method') },
    },
}

sub _has_events {
    submit => {},
}

sub _sel_js_form { $_[0]->_top_level_form ? undef : $_[0]->_sel_js_form }

sub _top_level_form { 1 }

sub _sel_form       { 'form' }
sub _sel_container  { 'form' }

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_ifdef($data->{submit_to}, sub {
            $_->set_attribute($self->_sel_form, action => shift);
        }))
        ->apply($self->_cb_apply_ifdef($data->{submit_method}, sub {
            $_->set_attribute($self->_sel_form, method => shift);
        }))
        ->apply($self->_cb_apply_common($self->_sel_form))
        ->select($self->_sel_container)
        ->append_content($self->_render_children($ctx))
        ->memoize;
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithChildren
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
