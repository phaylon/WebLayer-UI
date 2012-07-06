package WebLayer::UI::Component::Dialog::Simple::Field;
use Moo;
use WebLayer::UI::Util  qw( :js );
use Carp                qw( confess );
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _default_template {
    confess sprintf q!Class %s did not provide a _default_template!,
        ref shift;
}

sub _has_slots {
    label => {
        set => sub { js_set_text($_[0]->_sel_label, 'value') },
        get => sub { js_get_text($_[0]->_sel_label) },
    },
    message => {
        set => sub { js_set_text($_[0]->_sel_message, 'value') },
        get => sub { js_get_text($_[0]->_sel_message) },
    },
}

sub _sel_label   { '.ui-dialog-field-label' }
sub _sel_message { '.ui-dialog-field-message' }

sub _uncommon_events { 1 }

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_common('.ui-dialog-simple-row'))
        ->apply($self->_cb_apply_ifdef($data->{label}, sub {
            $_->replace_content('.ui-dialog-field-label', shift);
        }))
        ->apply($self->_cb_apply_ifdef($data->{message}, sub {
            $_->replace_content('.ui-dialog-field-message', shift);
        }));
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
