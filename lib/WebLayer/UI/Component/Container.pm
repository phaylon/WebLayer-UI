package WebLayer::UI::Component::Container;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :js :debug );
use HTML::Zoom;
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _has_slots {
    text => {
        set => sub { js_set_text(undef, 'value') },
        get => sub { js_get_text(undef) },
    },
    content => {
        set => sub { js_set_html(undef, 'value') },
        get => sub { js_get_html(undef) },
    },
}

sub _make_source_stream {
    my ($self) = @_;
    my $element = $self->_element;
    confess sprintf q!Container '%s' has no declared element type!,
        $self
        unless defined $element;
    return HTML::Zoom
        ->from_html(qq{<$element class="ui-container"></$element>});
}

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    my $body_content = $self->_render_children($ctx);
    return $markup
        ->apply($self->_cb_apply_common('.ui-container', $ctx))
        ->replace_content('.ui-container', $body_content)
        ->memoize
        ->apply($self->_cb_apply_ifdef($data->{text}, sub {
#            warn "APPLY TEXT " . $self->_element;
#            warn "TEXT " . $_[0];
#            warn "CURR " . $_->to_html;
            $_->replace_content('.ui-container', shift);
        }))
        ->apply($self->_cb_apply_ifdef($data->{content}, sub {
            # TODO find out how to generate reliable events from
            # H:Z instead of getting empty streams when no markup is
            # present
            $_->replace_content('.ui-container', shift);
        }))
        ->memoize;
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromStream
    WebLayer::UI::Component::Role::WithChildren
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
    WebLayer::UI::Component::Role::WithElement
);

1;
