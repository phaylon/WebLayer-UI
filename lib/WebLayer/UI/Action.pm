package WebLayer::UI::Action;
use Moo;
use namespace::clean;

has _ui => (
    init_arg    => 'ui',
    is          => 'ro',
    required    => 1,
);

has _continue_event => (is => 'rw');

has _continue_source => (
    is          => 'ro',
    init_arg    => 'continue_source',
    weak_ref    => 1,
    required    => 1,
);

sub _has_continue { defined $_[0]->_continue_event }

sub then {
    my ($self, $cb) = @_;
    my $event = $self->_continue_source->_child;
    do {
        local $_ = $event;
        $cb->();
    };
    $self->_continue_event($event);
    return $self;
}

sub new_from_values {
    my ($class, $values, %arg) = @_;
    return $class->new($class->_parse_construct_values(@$values), %arg);
}

sub _render_continue {
    my ($self) = @_;
    return sprintf q!function () { %s }!,
        $self->_continue_event->_render_actions;
}

sub _parse_construct_values { () }

sub _validate { 1 }

sub _init {
    my ($self, $cb) = @_;
    do { local $_ = $self; $cb->() };
    $self->_validate;
    return 1;
}

1;
