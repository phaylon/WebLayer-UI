package WebLayer::UI::Component::Input::Text;
use Moo;
use WebLayer::UI::Util  qw( :js );
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _default_template { 'input/text.html' }

sub _has_slots {
    value => {
        set => sub { js_set_attr($_[0]->_sel_js_root, 'value', 'value') },
        get => sub { js_get_attr($_[0]->_sel_js_root, 'value') },
    },
};

sub _sel_js_root { undef }
sub _sel_root    { '.ui-field-text' }

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_common($self->_sel_root))
        ->apply($self->_cb_apply_ifdef($data->{value}, sub {
            $_->set_attribute('.ui-field-text', value => shift);
        }));
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
