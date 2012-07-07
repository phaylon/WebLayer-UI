package WebLayer::UI::Action::Sync;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( json_enc );
use namespace::clean;

extends 'WebLayer::UI::Action';

has _from => (is => 'rw');
has _to   => (is => 'rw');

sub from { $_[0]->_from($_[1]); shift }
sub to   { $_[0]->_to($_[1]); shift }

sub _validate {
    my ($self) = @_;
    confess sprintf q{Action '%s' requires a 'from' value},
        $self,
        unless defined $self->_from;
    confess sprintf q{Action '%s' requires a 'to' value},
        $self,
        unless defined $self->_to;
    return 1;
}

sub _render {
    my ($self) = @_;
    return sprintf q!wlui.set(current, %s, wlui.get(current, %s))!,
        json_enc($self->_to),
        json_enc($self->_from);
}

1;
