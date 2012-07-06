package WebLayer::UI::Effect;
use Moo;
use WebLayer::UI::Util  qw( :json );
use Carp                qw( confess );
use namespace::clean;

extends 'WebLayer::UI::Action';

has _duration => (is => 'rw');

sub _has_duration { defined $_[0]->_duration }

sub duration { $_[0]->_duration($_[1]); $_[0] }

sub _validate {
    confess sprintf q{%s effect needs duration}, ref $_[0]
        unless defined $_[0]->_duration;
    return 1;
}

sub _render_selectors { json_enc join ', ', @{$_[0]->_targets} }

sub _render_duration {
    my ($self) = @_;
    my $duration = $self->_duration;
    return $duration
        if $duration =~ m{^[0-9]+};
    return json_enc($duration);
}

with $_ for qw(
    WebLayer::UI::Action::Role::WithTargets
);

1;
