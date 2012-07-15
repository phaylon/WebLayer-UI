package WebLayer::UI::Component::Role::WithPrototype;
use Moo::Role;
use Carp        qw( confess );
use namespace::clean;

has _prototype => (is => 'rw');

sub prototype { $_[0]->_prototype($_[1]); shift }

sub _require_prototype {
    my ($self) = @_;
    confess sprintf q{Component '%s' requires a prototype}, $self
        unless defined $self->_prototype;
    return $self->_prototype;
}

1;
