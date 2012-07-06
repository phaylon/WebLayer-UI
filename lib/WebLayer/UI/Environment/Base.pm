package WebLayer::UI::Environment::Base;
use Moo;
use namespace::clean;

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

sub _render_init {
    my ($self) = @_;
    return sprintf q!var weblayer_ui_env = { get: %s, set: %s };!,
}

with $_ for qw(
    WebLayer::UI::Environment::API
);

1;
