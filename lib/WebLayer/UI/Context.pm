package WebLayer::UI::Context;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :types :nested :json pp );
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

sub _render_with_subdata {
    my ($self, $item, $data) = @_;
    local $self->{_data} = { %{ $self->_data }, %{ unnest_data $data } };
#    pp $self->_data;
    return $self->_render($item);
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
