package WebLayer::UI::Component::Role::WithChildren;
use Moo::Role;
use HTML::Zoom;
use WebLayer::UI::Util  qw( isa_ref );
use namespace::clean;

has _collected_children => (
    is          => 'ro',
    isa         => isa_ref('ARRAY'),
    default     => sub { [] },
);

sub children {
    my ($self, @children) = @_;
    push @{$self->_collected_children}, @children;
    return $self;
}

sub _children { @{$_[0]->_collected_children} }

sub _render_children {
    my ($self, $ctx) = @_;
    return HTML::Zoom->from_html(join '',
        map $self->_render_child($ctx, $_)->to_html, $self->_children,
    );
}

sub _render_child {
    my ($self, $ctx, $child) = @_;
    return HTML::Zoom->from_events([{ raw => $child, type => 'TEXT' }])
        unless ref $child;
    return $ctx->_render($child);
}

1;
