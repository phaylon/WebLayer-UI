package WebLayer::UI::Action::Request;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :js :api );
use namespace::clean;

extends 'WebLayer::UI::Action';

has settable    send_method     => (default => sub { 'GET' });
has settable    send_to         => ();
has settable    send_via        => ();
has collectable send_values     => ();
has mappable    send_aliased    => ();

has _responses  => (is => 'ro', default => sub { {} });

sub _when_response {
    my ($self, $type, $name, $cb) = @_;
    my $event = $self->_ui
        ->make_special_event('Response::' . $type, $name);
    do { local $_ = $event; $cb->() };
    $self->_responses->{$name} = $event;
    return $self;
}

sub when_error   { $_[0]->_when_response('Error',   'error',   $_[1]) }
sub when_success { $_[0]->_when_response('Success', 'success', $_[1]) }

sub _render {
    my ($self) = @_;
    my $responses = $self->_responses;
    return sprintf q!wlui.request(current, %s, %s, %s)!,
        sprintf('function (gathered) { return { %s } }', join ', ',
            map join(': ', json_enc($_->[0]), $_->[1]),
            [type       => json_enc($self->_send_method)],
            [data       => 'gathered'],
            [dataType   => json_enc('json')],
            $self->_has_send_via
                ? [url => js_get($self->_send_via)]
                : [url => json_enc($self->_send_to)],
            $responses->{success}
                ? [success => $responses->{success}->_render_func]
                : (),
            $responses->{error}
                ? [error => $responses->{error}->_render_func]
                : (),
        ),
        json_enc([$self->_send_values]),
        json_enc({$self->_send_aliased_kv});
}

sub _validate {
    my ($self) = @_;
    confess q{You need to specify a target for the request}
        unless $self->_has_send_to or $self->_has_send_via;
    return 1;
}

1;
