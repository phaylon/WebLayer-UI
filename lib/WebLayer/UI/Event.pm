package WebLayer::UI::Event;
use Moo;
use namespace::clean;

has name => (is => 'ro', required => 1);

has _ui => (
    init_arg    => 'ui',
    is          => 'ro',
    required    => 1,
);

has _actions => (
    is          => 'ro',
    default     => sub { [] },
);

sub new_from_values {
    my ($class, $values, %arg) = @_;
    return $class->new($class->_parse_construct_values(@$values), %arg);
}

sub _parse_construct_values { () }

sub _render_actions {
    my ($self) = @_;
    return join ';',
        map $_->_render, @{$self->_actions};
}

sub sync {
    my ($self, @args) = @_;
    while (@args) {
        my $from = shift @args;
        my $to   = shift @args;
        $self->perform('Sync', sub {
            $_->from($from)->to($to);
        });
    }
    return $self;
}

sub perform {
    my ($self, $type, @args) = @_;
    my $cb_init = pop @args;
    my $action = $self->_ui->make_action($type, $self, @args);
    $action->_init($cb_init);
    push @{$self->_actions}, $action;
    return $self;
}

sub stop_event {
    my ($self) = @_;
    return $self->perform('Return', 'false', sub {});
}

sub continue_event {
    my ($self) = @_;
    return $self->perform('Return', 'true', sub {});
}

sub _child {
    my ($self) = @_;
    return ref($self)->new(ui => $self->_ui, name => $self->name);
}

sub effect {
    my ($self, $type, $cb) = @_;
    my $effect = $self->_ui->make_effect(
        $type,
        continue_source => $self,
    );
    do {
        local $_ = $effect;
        $cb->();
    };
    push @{$self->_actions}, $effect;
    return $self;
}

1;
