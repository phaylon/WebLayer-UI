package WebLayer::UI::Component::Dialog::Simple::Field::API;
use Moo::Role;
use WebLayer::UI::Util  qw( :js );
use namespace::clean;

around _has_slots => sub {
    my ($orig, $self) = @_;
    label => {
        set => sub { js_set_text($_[0]->_sel_label, 'value') },
        get => sub { js_get_text($_[0]->_sel_label) },
    },
    message => {
        set => sub { js_set_text($_[0]->_sel_message, 'value') },
        get => sub { js_get_text($_[0]->_sel_message) },
    },
    $self->$orig(),
};

sub _sel_label   { '.ui-dialog-field-label' }
sub _sel_message { '.ui-dialog-field-message' }

around _uncommon_events => sub { 1 };

around _prepare_markup => sub {
    my ($orig, $self, $ctx, $markup, $data) = @_;
    return $self->$orig($ctx, $markup, $data)
        ->apply($self->_cb_apply_common('.ui-dialog-simple-row', $ctx))
        ->apply($self->_cb_apply_ifdef($data->{label}, sub {
            $_->replace_content('.ui-dialog-field-label', shift);
        }))
        ->apply($self->_cb_apply_ifdef($data->{message}, sub {
            $_->replace_content('.ui-dialog-field-message', shift);
        }));
};

1;
