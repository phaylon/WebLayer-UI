package WebLayer::UI::Context;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :types :nested :json );
use namespace::clean;

has _ui => (
    init_arg    => 'ui',
    is          => 'ro',
    required    => 1,
    isa         => isa_instance('WebLayer::UI', q{Attribute 'ui'}),
    handles     => [qw( make file dir slurp )],
);

has _data => (
    init_arg    => 'data',
    is          => 'ro',
    required    => 1,
    isa         => isa_ref('HASH', q{Attribute 'data'}),
);

has _inputs => (
    is          => 'ro',
    default     => sub { {} },
);

has _outputs => (
    is          => 'ro',
    default     => sub { {} },
);

sub _get_value {
    my ($self, $name) = @_;
    return get_nested $self->_data, $name;
}

sub _render {
    my ($self, $item) = @_;
    return $item->_render_with_context($self);
}

sub _ensure_output {
    my ($self, $name, $expr) = @_;
    $self->_outputs->{$name} = $expr;
    return 1;
}

sub _ensure_input {
    my ($self, $name, $expr) = @_;
    $self->_inputs->{$name} = $expr;
    return 1;
}

sub _render_js_io {
    my ($self) = @_;
    return join '', map "$_;\n",
        $self->_render_inputs,
        $self->_render_outputs;
}

sub _render_outputs {
    my ($self) = @_;
    my $outputs = $self->_outputs;
    return map {
        sprintf(q!wlui.addGetter(%s, function (root) { %s })!,
            json_enc($_),
            $outputs->{$_},
        );
    } sort keys %$outputs;
}

sub _render_inputs {
    my ($self) = @_;
    my $inputs = $self->_inputs;
    return map {
        sprintf(q!wlui.addSetter(%s, function (root, value) { %s })!,
            json_enc($_),
            $inputs->{$_},
        );
    } sort keys %$inputs;
}

1;

__END__

sub _add_input {
    my ($self, $name, $body) = @_;
    push @{ $self->_inputs->{$name} ||= [] }, $body;
    return 1;
}

sub _add_output {
    my ($self, $name, $body) = @_;
    confess sprintf "Only a single component can provide the value '%s'",
        $name
        if exists $self->_outputs->{$name};
    $self->_outputs->{$name} = [$body];
    return 1;
}

sub _render_js_io {
    my ($self) = @_;
    return join '', map "$_;\n",
        $self->_render_inputs,
        $self->_render_outputs;
}

my $_render_map = sub {
    my ($self, $attr, $params, $template) = @_;
    my $channels = $self->$attr;
    return sprintf "{%s}", join ', ', map {
        my $name   = $_;
        my $bodies = $channels->{$name};
        sprintf "%s: %s\n", json_enc($name),
            sprintf $template, join ', ', map {
                sprintf 'function (%s) { %s; }', $params, $_;
            } @$bodies;
    } keys %$channels;
};

sub _render_inputs {
    my ($self) = @_;
    my $channels = $self->_inputs;
    return map {
        my $channel = $_;
        sprintf(q!wlui.addSetter(%s, %s)!,
            json_enc($channel),
        );
    } sort keys %$channel;
}

sub _render_input_map  { $_[0]->$_render_map('_inputs', 'value', '[%s]') }
sub _render_output_map { $_[0]->$_render_map('_outputs', '', '%s') }

1;
