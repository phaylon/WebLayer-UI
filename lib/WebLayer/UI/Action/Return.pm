package WebLayer::UI::Action::Return;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Action';

has _expression => (init_arg => 'expression', is => 'ro', required => 1);

sub _parse_construct_values {
    my ($self, $expr) = @_;
    return expression => $expr;
}

sub _render { sprintf 'return %s', $_[0]->_expression }

1;
