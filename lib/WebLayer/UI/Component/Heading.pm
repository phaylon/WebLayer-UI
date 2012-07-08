package WebLayer::UI::Component::Heading;
use Moo;
use WebLayer::UI::Util  qw( :js :debug );
use Carp                qw( confess );
use HTML::Zoom;
use namespace::clean;

extends 'WebLayer::UI::Component';

has _level => (is => 'rw');

sub level { $_[0]->_level($_[1]); shift }

sub _has_slots {
    content => {
        set => sub { js_set_html(undef, 'value') },
        get => sub { js_get_html(undef) },
    },
}

sub _make_source_stream {
    my ($self) = @_;
    my $level = $self->_level;
    confess sprintf q!Heading '%s' has no declared level!,
        $self,
        unless defined $level;
    return HTML::Zoom
        ->from_html(qq{<h$level class="ui-heading"></h$level>});
}

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_common('.ui-heading', $ctx))
        ->apply($self->_cb_apply_ifdef($data->{content}, sub {
            $_->replace_content('.ui-heading', shift);
        }))
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromStream
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
