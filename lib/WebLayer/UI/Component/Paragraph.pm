package WebLayer::UI::Component::Paragraph;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Container';

sub BUILD {
    my ($self) = @_;
    $self->classes('ui-paragraph')
         ->element('p');
}

1;

__END__
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
    my $body_content = $self->_render_children($ctx);
    return $markup
        ->apply($self->_cb_apply_common('.ui-paragraph'))
        ->replace_content('.ui-paragraph', $body_content)
        ->apply($self->_cb_apply_ifdef($data->{content}, sub {
            $_->replace_content('.ui-paragraph', shift);
        }));
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
    WebLayer::UI::Component::Role::WithChildren
);

1;
