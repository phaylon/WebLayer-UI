package WebLayer::UI::Event::Response::Success;
use Moo;
use WebLayer::UI::Util  qw( :json );
use namespace::clean;

extends 'WebLayer::UI::Event';

has _populations => (is => 'ro', default => sub { [] });
has _conditions  => (is => 'ro', default => sub { [] });

sub populate {
    my ($self, @values) = @_;
    push @{$self->_populations}, @values;
    return $self;
}

sub _when_cond {
    my ($self, $pred, $value, $cb, @args) = @_;
    my $event = $self->_child;
    do {
        local $_ = $event;
        $cb->();
    };
    push @{$self->_conditions}, [$pred, $value, $event, @args];
    return $self;
}

sub when_eq {
    my ($self, $value, $string, $cb) = @_;
    return $self->_when_cond('eq', $value, $cb, $string);
}

sub when_false {
    my ($self, $value, $cb) = @_;
    return $self->_when_cond('false', $value, $cb);
}

sub when_true {
    my ($self, $value, $cb) = @_;
    return $self->_when_cond('true', $value, $cb);
}

sub _render_body {
    my ($self) = @_;
    return join ';',
        $self->_render_populations,
        $self->_render_conditions,
        $self->_render_actions;
}

sub _render_func {
    my ($self) = @_;
    return sprintf q!function (data, text_status, xhr) { %s }!,
        $self->_render_body;
}

sub _render_conditions {
    my ($self) = @_;
    return join ';', map {
        my ($pred, $value, $event, @args) = @$_;
        sprintf q!if (%s) { %s }!,
            $self->_render_condition_pred($pred, $value, @args),
            $event->_render_body;
    } @{$self->_conditions};
}

sub _render_condition_pred {
    my ($self, $pred, $value, @args) = @_;
    if ($pred eq 'eq') {
        return sprintf 'data[%s] == %s',
            json_enc($value),
            json_enc($args[0]);
    }
    elsif ($pred eq 'false') {
        return sprintf '!data[%s]', json_enc($value);
    }
    elsif ($pred eq 'true') {
        return sprintf 'data[%s]', json_enc($value);
    }
    else {
        die "Unknown predicate $pred";
    }
}

sub _render_populations {
    my ($self) = @_;
    return join ';', map {
        sprintf q!wlui.set(current, %s, data[%s])!,
            json_enc($_),
            json_enc($_);
    } @{$self->_populations};
}

1;
