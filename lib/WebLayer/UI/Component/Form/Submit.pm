package WebLayer::UI::Component::Form::Submit;
use Moo;
use WebLayer::UI::Util  qw( :js );
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _default_template { 'form/submit.html' }

sub _has_slots {
    label => {
        set => sub { js_set_attr($_[0]->_sel_submit, 'value', 'value') },
        get => sub { js_get_attr($_[0]->_sel_submit, 'value') },
    },
}

sub _sel_input { (shift)->_js_id_fb . ' .ui-form-submit' }

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_ifdef($data->{label}, sub {
            $_->set_attribute('.ui-form-submit', value => shift);
        }))
        ->apply($self->_cb_apply_common('.ui-form-submit', $ctx))
        ->memoize;
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
