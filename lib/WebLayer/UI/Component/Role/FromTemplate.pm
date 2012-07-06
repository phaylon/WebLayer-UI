package WebLayer::UI::Component::Role::FromTemplate;
use Moo::Role;
use HTML::Zoom;
use namespace::clean;

requires qw(
    _default_template
    _prepare_markup
);

has _template => (is => 'rw');

sub template { $_[0]->_template($_[1]); $_[0] }

sub _render {
    my ($self, $ctx, $data) = @_;
    my $template = $self->_find_template($ctx);
    my $markup   = HTML::Zoom->from_file($template);
    return $self->_prepare_markup($ctx, $markup, $data);
}

sub _find_template {
    my ($self, $ctx) = @_;
    my $template = $self->_template;
    $template = $ctx->file(templates => $self->_default_template)
        unless defined $template;
    return $template;
}

1;
