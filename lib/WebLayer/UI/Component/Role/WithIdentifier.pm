package WebLayer::UI::Component::Role::WithIdentifier;
use Moo::Role;
use Carp        qw( confess );
use namespace::clean;

has _identifier => (is => 'rw');

sub _has_id { defined $_[0]->_identifier }
sub _id { $_[0]->_identifier }
sub _js_id { '#' . $_[0]->_require_id }

sub id { $_[0]->_identifier($_[1]); $_[0] }

sub _require_id {
    my ($self) = @_;
    confess sprintf q!Component class %s requires an id!,
        ref($self)
        unless $self->_has_id;
    return $self->_id;
}

sub _cb_apply_id {
    my ($self, $selector, $template) = @_;
    return sub { $_ }
        unless $self->_has_id;
    $template = '%s'
        unless defined $template;
    return sub {
        return $_->set_attribute(
            $selector,
            id => sprintf $template, $self->_id,
        );
    };
}

around _apply_common => sub {
    my ($orig, $self, $markup, $selector) = @_;
    return $self->$orig($markup, $selector)
        ->apply($self->_cb_apply_id($selector));
};

1;
