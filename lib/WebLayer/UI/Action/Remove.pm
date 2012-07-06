package WebLayer::UI::Action::Remove;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( json_enc );
use namespace::clean;

extends 'WebLayer::UI::Action';

sub _validate {
    my ($self) = @_;
    return 1;
}

sub _render {
    my ($self) = @_;
    return sprintf q!$.each([%s], function (i, v) { $(v).remove() })!,
        join ', ', map json_enc($_), @{$self->_targets};
}

with $_ for qw(
    WebLayer::UI::Action::Role::WithTargets
);

1;
