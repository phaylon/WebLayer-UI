package WebLayer::UI::Component::Dialog::Simple::Field::Password;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Dialog::Simple::Field::Text';

around _prepare_markup => sub {
    my ($orig, $self, $ctx, $markup, $data) = @_;
    return $self->$orig($ctx, $markup, $data)
        ->select('.ui-field-text')
        ->set_attribute(type => 'password')
        ->then
        ->add_to_attribute(class => 'ui-field-password');
};

1;
