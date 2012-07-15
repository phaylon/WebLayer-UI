package WebLayer::UI::Component::Role::WithCollection;
use Moo::Role;
use HTML::Zoom;
use WebLayer::UI::Util  qw( :js :strings );
use aliased 'WebLayer::UI::Collection';
use namespace::clean;

requires qw(
    _prepare_element_markup
);

has _collection => (is => 'ro', builder => 1);

my $_cid = 0;

has _cid => (is => 'ro', default => sub { 'cid-' . $_cid++ });

sub _build__collection { Collection->new }

sub _collection_mapping { shift->_collection->_contains }

around _has_slots => sub {
    my ($orig, $self) = @_;
    $self->$orig,
    all => {
        get => sub {
            return js_code q!
                wlui.collGetAll(root, %(json:mappings));
            !, mappings => $self->_collection_mapping;
        },
        set => sub {
            return js_code q!
                wlui.collSetAll(root, %(json:mappings), value);
            !, mappings => $self->_collection_mapping;
        },
    },
};

sub collection {
    my ($self, $cb) = @_;
    do {
        local $_ = $self->_collection;
        $cb->();
    };
    return $self;
}

sub _remap_data {
    my ($self, $data) = @_;
    my $mapping = $self->_collection_mapping;
    my %remapped;
    for my $key (keys %$mapping) {
        if (exists $data->{$key}) {
            $remapped{$mapping->{$key}} = $data->{$key};
        }
    }
    return \%remapped;
}

sub _render_collection_element {
    my ($self, $ctx, $data) = @_;
    my $element  = $self->_require_prototype;
    my $remapped = $self->_remap_data($data);
    my $markup   = $ctx->_render_with_subdata($element, $remapped);
    my $sel     = $self->_sel_item_root;
    return $self->_prepare_element_markup($ctx, $markup, $self->_cid);
}

sub _render_prototype_element {
    my ($self, $ctx) = @_;
    my $element = $self->_require_prototype;
    my $markup  = $ctx->_render($element);
    my $sel     = $self->_sel_item_root;
    return $self->_prepare_element_markup($ctx, $markup, $self->_cid)
        ->add_to_attribute($sel, class => 'prototype')
        ->add_to_attribute($sel, style => ';display:none;');
}

sub _sel_item_root { sprintf '.%s', shift->_cid }

sub _collection_elements {
    my ($self, $ctx, $data) = @_;
    my $rows = $data->{all} || [];
    return HTML::Zoom->from_html(join '',
        $self->_render_prototype_element($ctx)->to_html,
        (map {
            $self->_render_collection_element($ctx, $_)->to_html;
        } @$rows),
    );
}

sub _cb_apply_collection {
    my ($self, $selector, $ctx, $data) = @_;
    return sub {
        $_->replace_content(
            $selector,
            $self->_collection_elements($ctx, $data),
        );
    };
}

with $_ for qw(
    WebLayer::UI::Component::Role::WithPrototype
);

1;
