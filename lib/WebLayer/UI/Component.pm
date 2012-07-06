package WebLayer::UI::Component;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :types :json );
use HTML::Zoom;
use namespace::clean;

my $_comp_idx = 0;

has _component_index => (
    init_arg    => undef,
    is          => 'ro',
    lazy        => 1,
    default     => sub { $_comp_idx++ },
);

has _ui => (
    init_arg    => 'ui',
    is          => 'ro',
    required    => 1,
);

has _slots => (
    is          => 'ro',
    lazy        => 1,
    builder     => 1,
    isa         => isa_ref('HASH', q{Component slot definition}),
);

has _possible_events => (
    is          => 'ro',
    lazy        => 1,
    builder     => 1,
    isa         => isa_ref('HASH', q{Component event definition}),
);

has _events             => (is => 'ro', default => sub { [] });
has _static_inputs      => (is => 'ro', default => sub { {} });
has _runtime_inputs     => (is => 'ro', default => sub { {} });
has _runtime_outputs    => (is => 'ro', default => sub { {} });
has _fixed_values       => (is => 'ro', default => sub { {} });
has _is_hidden          => (is => 'rw');

my $_set_slot = sub {
    my ($self, $type, @set) = @_;
    my $store = $self->$type;
    while (my $slot = shift @set) {
        my $name = shift @set;
        confess "Unknown slot '$_'"
            unless $self->_slots->{$slot};
        if ($type ne '_static_inputs' and $type ne '_fixed_values') {
            confess "Slot '$slot' can only be set during rendering"
                if $self->_slots->{$slot}{render_only};
        }
        $store->{$slot} = $name;
#        push @{ $store->{$slot} ||= [] }, $name;
    }
    return $self;
};

sub static   { $_[0]->$_set_slot(_static_inputs => @_[1 .. $#_]) }
sub receives { $_[0]->$_set_slot(_runtime_inputs => @_[1 .. $#_]) }
sub provides { $_[0]->$_set_slot(_runtime_outputs => @_[1 .. $#_]) }
sub fixed    { $_[0]->$_set_slot(_fixed_values => @_[1 .. $#_]) }
sub hidden   { $_[0]->_is_hidden(1); $_[0] }

sub _cb_apply_common {
    my ($self, $selector) = @_;
    return sub {
        return $self->_apply_common($_, $selector);
    };
}

sub _uncommon_events { 0 }

sub _apply_common {
    my ($self, $markup, $selector) = @_;
    $markup = $self->_apply_styles($markup, $selector);
    $markup = $self->_apply_env_data($markup, $selector);
    return $markup
        if $self->_uncommon_events;
    return $markup->apply($self->_cb_apply_events($selector));
}

sub _apply_env_data {
    my ($self, $markup, $selector) = @_;
    my $inputs  = $self->_runtime_inputs;
    my $outputs = $self->_runtime_outputs;
    $markup = $markup
        ->add_to_attribute($selector, 'data-wlui-in', $inputs->{$_})
        for keys %$inputs;
    $markup = $markup
        ->add_to_attribute($selector, 'data-wlui-out', $outputs->{$_})
        for keys %$outputs;
    if (keys %$inputs or keys %$outputs) {
        $markup = $markup->set_attribute($selector, 'data-wlui-api',
            json_enc({ map {
                my ($type, $map) = @$_;
                keys(%$map) ? ($type => { map {
                    ($map->{$_}, join ':',
                        $self->_component_index,
                        $type,
                        $_);
                } keys %$map }) : ();
            } [set => $inputs], [get => $outputs] }),
        );
    }
    return $markup;
}

sub _apply_styles {
    my ($self, $markup, $selector) = @_;
    my @styles;
    push @styles, 'display: none'
        if $self->_is_hidden;
    return $markup
        unless @styles;
    return $markup->add_to_attribute($selector, style => sprintf(';%s',
        join ';', @styles,
    ));
}

sub on {
    my ($self, $event_name, @args) = @_;
    my $cb_init    = pop @args;
    my $event_spec = $self->_possible_events->{$event_name};
    confess qq{Unknown event '$event_name'}
        unless defined $event_spec;
    my $event = $self->_ui->make_event($event_name, @args);
    do { local $_ = $event; $cb_init->() };
    push @{$self->_events}, $event;
    return $self;
}

sub _cb_apply_events {
    my ($self, $selector) = @_;
    my %by_name;
    for my $event (@{ $self->_events }) {
        push @{$by_name{ $event->name }}, $event->_render_actions;
    }
    return sub {
        my $zoom = $_;
        $zoom = $zoom->set_attribute(
            $selector,
            "on$_",
            join ';', 'var current = this', @{$by_name{$_}},
        ) for sort keys %by_name;
        return $zoom;
    };
}

sub _has_events {
    click => {},
}

sub _build__possible_events { +{ $_[0]->_has_events } }

sub _has_slots { () }

sub _build__slots { +{ $_[0]->_has_slots } }

sub _ensure_complete {
    my ($self) = @_;
    my $slots = $self->_slots;
    my %required = map { ($_, 1) }
        grep { $slots->{$_}{required} }
        keys %$slots;
    my %required_param = %required;
    delete $required{$_}
        for keys(%{ $self->_static_inputs }),
            keys(%{ $self->_runtime_inputs }),
            keys(%{ $self->_fixed_values });
    confess sprintf q!Components '%s' is missing access to values %s!,
        $self,
        join ', ', map "'$_'", sort keys %required
        if keys %required;
    for my $fixed (keys %{ $self->_fixed_values }) {
        delete $required_param{ $fixed };
    }
    $required_param{$_}
        = $self->_static_inputs->{$_}
          || $self->_runtime_inputs->{$_}
        for keys %required_param;
    return \%required_param;
}

sub _gather_data {
    my ($self, $ctx) = @_;
    my $require = $self->_ensure_complete;
    my $static  = $self->_static_inputs;
    my $inputs  = $self->_runtime_inputs;
    my $data = +{
        (map {
            my $val = $ctx->_get_value($static->{$_});
            defined($val) ? ($_, $val) : ();
        } keys %$static),
        (map {
            my $val = $ctx->_get_value($inputs->{$_});
            defined($val) ? ($_, $val) : ();
        } keys %$inputs),
        %{ $self->_fixed_values },
    };
    for my $required (keys %$require) {
        confess sprintf q!Components '%s' expected a '%s' via '%s'!,
            $self, $required, $require->{$required}
            unless exists $data->{$required};
    }
    return $data;
}

my $_add_channels = sub {
    my ($self, $ctx, $attr, $add, $prop) = @_;
    my $channels = $self->$attr;
    my $id = $self->_component_index;
    for my $slot (sort keys %$channels) {
        my $via = $self->_slots->{$slot}{$prop};
        confess "Slot '$slot' does not have a '$prop' property"
            unless defined $via;
        my @id = ($id, $prop, $slot);
        $ctx->$add(
            join(':', @id),
            (ref($via) eq 'CODE') ? $self->$via : $via,
        );
    }
};

sub _render_with_context {
    my ($self, $ctx) = @_;
    $self->$_add_channels($ctx,
        '_runtime_inputs', '_ensure_input', 'set');
    $self->$_add_channels($ctx,
        '_runtime_outputs', '_ensure_output', 'get');
    my $data = $self->_gather_data($ctx);
    return $self->_render($ctx, $data);
}

sub _render {
    confess sprintf q{Components %s did not provide a _render method},
        ref($_[0]);
}

sub _cb_apply_ifdef {
    my ($self, $value, $code) = @_;
    return sub { $_ }
        unless defined $value;
    return sub { $code->($value) };
}

sub _join_markup {
    my ($self, @markup) = @_;
    return HTML::Zoom->from_html(join "\n", map $_->to_html, @markup);
}

1;
