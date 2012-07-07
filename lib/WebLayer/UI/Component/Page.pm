package WebLayer::UI::Component::Page;
use Moo;
use HTML::Zoom;
use HTML::Entities qw( encode_entities );
use WebLayer::UI::Util  qw( :js );
use namespace::clean;

extends 'WebLayer::UI::Component';

sub _default_template { 'page.html' }

sub _has_slots {
    title => {
        get => js_get_text('head > title'),
        set => js_set_text('head > title', 'value'),
    },
    scripts => {
        render_only => 1,
    },
    stylesheets => {
        render_only => 1,
    },
    jquery_uri => {
        render_only => 1,
        required => 1,
    },
    wlui_js_uri => {
        render_only => 1,
        required => 1,
    },
}

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    my $body_content = $self->_render_children($ctx);
    return $markup
        ->apply($self->_cb_apply_ifdef($data->{title}, sub {
            $_->replace_content('title', shift);
        }))
        ->apply($self->_cb_apply_ifdef($data->{stylesheets}, sub {
            $_->append_content('head', $self->_render_css(shift));
        }))
        ->apply($self->_cb_apply_ifdef($data->{scripts}, sub {
            $_->append_content('head', $self->_render_scripts(shift));
        }))
        ->set_attribute('#jquery-uri', src => $data->{jquery_uri})
        ->set_attribute('#wlui-js-uri', src => $data->{wlui_js_uri})
        ->select('head')
        ->append_content($self->_render_js_setup($ctx))
        ->apply($self->_cb_apply_common('html'))
        ->select('body')
        ->replace_content($body_content);
}

sub _render_css {
    my ($self, $css) = @_;
    return HTML::Zoom->from_html(join '', map {
        sprintf qq!<link rel="stylesheet" href="%s" />\n!,
            $_;
    } @$css);
}

sub _render_scripts {
    my ($self, $scripts) = @_;
    return HTML::Zoom->from_html(join '', map {
        sprintf qq!<script type="text/javascript" src="%s"></script>\n!,
            $_;
    } @$scripts);
}

sub _render_js_setup {
    my ($self, $ctx) = @_;
    return HTML::Zoom->from_html(sprintf
        qq!<script %s>\$(function () {\n%s})</script>!,
        'type="text/javascript"',
        join('', map "$_;\n",
            $ctx->_render_js_io,
        ),
    );
}

sub _load_js_preamble {
    my ($self, $ctx) = @_;
    return scalar $ctx->slurp('js/preamble.js');
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithChildren
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
);

1;
