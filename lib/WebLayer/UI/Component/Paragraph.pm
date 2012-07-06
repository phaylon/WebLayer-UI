package WebLayer::UI::Component::Paragraph;
use Moo;
use WebLayer::UI::Util  qw( :js );
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _default_template { 'paragraph.html' }

sub _has_slots {
    content => {
        set => sub { js_set_html(undef, 'value') },
        get => sub { js_get_html(undef) },
    },
}

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    return $markup
        ->apply($self->_cb_apply_common('.ui-paragraph'))
        ->apply($self->_cb_apply_ifdef($data->{content}, sub {
            $_->replace_content('.ui-paragraph', shift);
        }))
        ->memoize;
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
