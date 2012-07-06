package WebLayer::UI::Action::Request;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( json_enc );
use namespace::clean;

extends 'WebLayer::UI::Action';

has _method     => (is => 'rw', default => sub { 'GET' });
has _target     => (is => 'rw');
has _values     => (is => 'ro', default => sub { [] });
has _responses  => (is => 'ro', default => sub { {} });

sub send_method { $_[0]->_method($_[1]); $_[0] }
sub send_to     { $_[0]->_target($_[1]); $_[0] }
sub send_values { push @{$_[0]->_values}, @_[1 .. $#_]; $_[0] }

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
    return sprintf q!wlui.request(current, %s, %s)!,
        sprintf('function (gathered) { return { %s } }', join ', ',
            map join(': ', json_enc($_->[0]), $_->[1]),
            [type       => json_enc($self->_method)],
            [url        => json_enc($self->_target)],
            [data       => 'gathered'],
            [dataType   => json_enc('json')],
            $responses->{success}
                ? [success => $responses->{success}->_render_func]
                : (),
            $responses->{error}
                ? [error => $responses->{error}->_render_func]
                : (),
        ),
        json_enc($self->_values);
}

sub _validate {
    my ($self) = @_;
    confess q{You need to specify a target for the request}
        unless defined $self->_target;
    return 1;
}

1;
