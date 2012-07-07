package WebLayer::UI::Component::Segment;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->classes('ui-segment')
         ->element('span');
}

1;

__END__
use Moo;
use WebLayer::UI::Util  qw( :js );
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
    return HTML::Zoom
        ->from_html(q{<span class="ui-segment"></span>});
}

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_common('.ui-segment'))
        ->apply($self->_cb_apply_ifdef($data->{content}, sub {
            $_->replace_content('.ui-segment', shift);
        }));
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromStream
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
