package WebLayer::UI::Component::Role::WithClasses;
use Moo::Role;
use namespace::clean;

has _additional_classes => (
    is          => 'ro',
    default     => sub { [] },
);

sub _classes { @{$_[0]->_additional_classes} }
sub _has_classes { scalar $_[0]->_classes }
sub _joined_classes { join ' ', $_[0]->_classes }

sub classes { @{$_[0]->_additional_classes} = @_[1 .. $#_]; $_[0] }

sub _cb_apply_classes {
    my ($self, $selector) = @_;
    return sub { $_ }
        unless $self->_has_classes;
    return sub {
        return $_->add_to_attribute(
            $selector,
            class => $self->_joined_classes,
        );
    };
}

around _apply_common => sub {
    my ($orig, $self, $markup, $selector, $ctx) = @_;
    return $self->$orig($markup, $selector, $ctx)
        ->apply($self->_cb_apply_classes($selector));
};

1;
