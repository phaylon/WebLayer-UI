package WebLayer::UI::Component::Link;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :js :types :strings :api );
use HTML::Zoom;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->element('a');
}

around _has_slots => sub {
    my ($orig, $self) = @_;
    $self->$orig,
    href => {
        set => sub { js_set_attr(undef, 'href', 'value') },
        get => sub { js_get_attr(undef, 'href') },
    },
};

around _make_source_stream => sub {
    my ($orig, $self) = @_;
    return $self->$orig
        ->add_to_attribute('a', class => 'ui-link')
        ->set_attribute('a', href => '#')
        ->memoize
};

around _prepare_markup => sub {
    my ($orig, $self, $ctx, $markup, $data) = @_;
    $markup = $markup->set_attribute('a', href => $data->{href})
        if defined $data->{href};
    return $self->$orig($ctx, $markup, $data);
};

1;
