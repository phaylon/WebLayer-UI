package WebLayer::UI::Component::Switchable::Bool;
use Moo;
use Carp                qw( confess );
use WebLayer::UI::Util  qw( :js :types :strings :api );
use HTML::Zoom;
use namespace::clean;

extends 'WebLayer::UI::Component';

has settable transition => (
    clearer => 'no_transition',
    isa => isa_duration('Attribute transition'),
);

has settable case_false => (
    isa => isa_component('Attribute case_true'),
);

has settable case_true => (
    isa => isa_component('Attribute case_true'),
);

sub _has_slots {
    my ($self) = @_;
    my $cid = $self->_component_index;
    my $transition = $self->_transition;
    my $trans_func = defined($transition)
        ? js_code(q!
            function (to_hide, to_show) {
                to_hide.hide(%(json:trans), function () {
                    to_show.show(%(json:trans));
                });
            }
          !, trans => $transition)
        : js_code(q!
            function (to_hide, to_show) {
                to_hide.hide();
                to_show.show();
            }
          !);
    state => {
        get => sub {
            return js_code q!
                var visible = $('> .switch-%(raw:cid)', root).first();
                return $(visible).hasClass('on');
            !, cid => $cid;
        },
        set => sub {
            return js_code q!
                var trans = %(raw:trans_func);
                var on    = $('> .switch-%(raw:cid).on', root);
                var off   = $('> .switch-%(raw:cid).off', root);
                if (value) {
                    trans(off, on);
                }
                else {
                    trans(on, off);
                }
                return true;
            !, cid => $cid, trans_func => $trans_func;
        },
    },
}

sub _make_source_stream {
    my ($self) = @_;
    my $tag = $self->_element_or_default('span');
    my $cid = $self->_component_index;
    return HTML::Zoom->from_html(tight_singleline qq{
        <$tag class="ui-switch-bool">
            <$tag class="switch-$cid on"></$tag>
            <$tag class="switch-$cid off"></$tag>
        </$tag>
    });
}

my $_apply = sub {
    my ($self, $ctx, $markup, $class, $comp) = @_;
    return $markup->replace_content(".$class", $ctx->_render($comp));
};

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    $markup = $markup
        ->apply($self->_cb_apply_common('.ui-switch-bool', $ctx))
        ->add_to_attribute(
            $data->{state} ? '.off' : '.on',
            style => ';display: none;',
        )
        ->memoize;
    $markup = $self->$_apply($ctx, $markup, 'on', $self->_case_true)
        if $self->_has_case_true;
    $markup = $self->$_apply($ctx, $markup, 'off', $self->_case_false)
        if $self->_has_case_false;
    return $markup;
}

with $_ for qw(
    WebLayer::UI::Component::Role::FromStream
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
    WebLayer::UI::Component::Role::WithElement
);

1;
