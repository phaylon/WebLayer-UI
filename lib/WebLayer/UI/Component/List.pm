package WebLayer::UI::Component::List;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :js :debug );
use HTML::Zoom;
use namespace::clean;

extends 'WebLayer::UI::Component';

has _is_ordered => (is => 'rw');

sub ordered   { $_[0]->_is_ordered(1); shift }
sub unordered { $_[0]->_is_ordered(0); shift }

sub _make_source_stream {
    my ($self) = @_;
    my $tag = $self->_is_ordered ? 'ol' : 'ul';
    return HTML::Zoom
        ->from_html(qq{<$tag class="ui-list"></$tag>});
}

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_common('.ui-list', $ctx))
        ->apply($self->_cb_apply_collection('.ui-list', $ctx, $data));
}

sub _prepare_element_markup {
    my ($self, $ctx, $markup, $cid) = @_;
    return HTML::Zoom
        ->from_html(qq{<li data-wlui-barrier="true" class="$cid"></li>})
        ->replace_content('li', $markup);
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromStream
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
    WebLayer::UI::Component::Role::WithCollection
);

1;
