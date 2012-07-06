package WebLayer::UI::Component::Dialog::Simple::Field::Text;
use Moo;
use WebLayer::UI::Util  qw( :js );
use namespace::clean;

extends 'WebLayer::UI::Component::Dialog::Simple::Field';

sub _default_template { 'dialog/simple/field/text.html' }

around _has_slots => sub {
    my ($orig, $self) = @_;
    value => {
        set => sub { js_set_attr('.ui-field-text', 'value', 'value') },
        get => sub { js_get_attr('.ui-field-text', 'value') },
    },
    $self->$orig,
};

around _prepare_markup => sub {
    my ($orig, $self, $ctx, $markup, $data) = @_;
    return $self->$orig($ctx, $markup, $data)
        ->apply($self->_cb_apply_events('.ui-field-text'))
        ->apply($self->_cb_apply_ifdef($data->{value}, sub {
            $_->set_attribute('.ui-field-text', value => shift);
        }));
};

1;
