package WebLayer::UI::Collection;
use Moo;
use namespace::clean;

has _keyed_by => (is => 'rw');
has _contains => (is => 'ro', default => sub { {} });

sub keyed_by { $_[0]->_keyed_by($_[1]); shift }

sub contains {
    my ($self, %set) = @_;
    $self->_contains->{$_} = $set{$_}
        for keys %set;
    return $self;
}

1;
