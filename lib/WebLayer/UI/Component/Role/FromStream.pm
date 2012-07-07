package WebLayer::UI::Component::Role::FromStream;
use Moo::Role;
use HTML::Zoom;
use namespace::clean;

requires qw(
    _prepare_markup
    _make_source_stream
);

sub _render {
    my ($self, $ctx, $data) = @_;
    my $markup = $self->_make_source_stream;
    return $self->_prepare_markup($ctx, $markup, $data)->memoize;
}

1;
