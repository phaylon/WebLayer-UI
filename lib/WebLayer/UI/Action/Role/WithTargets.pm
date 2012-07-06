package WebLayer::UI::Action::Role::WithTargets;
use Moo::Role;
use namespace::clean;

has _targets => (is => 'ro', default => sub { [] });

sub targets { push @{$_[0]->_targets}, @_[1 .. $#_]; $_[0] }

1;
