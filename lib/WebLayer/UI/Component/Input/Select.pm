package WebLayer::UI::Component::Input::Select;
use Moo;
use HTML::Zoom;
use WebLayer::UI::Util  qw( :js :strings );
use namespace::clean;

extends 'WebLayer::UI::Component';

has _multiple => (is => 'rw');

sub multiple { $_[0]->_multiple(1); shift }
sub single   { $_[0]->_multiple(undef); shift }

has _empty_label    => (is => 'rw');
has _empty_hidden   => (is => 'rw');

sub empty { $_[0]->_empty_label($_[1]); shift }
sub hide_empty { $_[0]->_empty_hidden(1); shift }

sub _default_template { 'input/select.html' }

sub _has_empty { defined $_[0]->_empty_label }

sub _has_slots {
    size => {
        set => sub { js_set_attr($_[0]->_sel_js_root, 'size', 'value') },
        get => sub { js_get_attr($_[0]->_sel_js_root, 'size') },
    },
    options => {
        get => sub {
            return js_code q!
                var sel  = %(json:sel_root);
                var from = sel ? $(sel, root) : $(root);
                var data = [];
                $('option:not([class~="unreal"])', from)
                    .each(function (i, elem) {
                        data.push({
                            key:    $(elem).attr('value'),
                            value:  $(elem).html(),
                        });
                    });
                return data;
            !,  sel_root => $_[0]->_sel_js_root,
        },
        set => sub {
            return js_code q!
                var sel   = %(json:sel_root);
                var from  = sel ? $(sel, root) : $(root);
                var mark  = 'option:not([class~="unreal"])';
                $(mark, from).remove();
                var elems = [];
                $.each(value, function (i, option) {
                    if (\!$(option).hasClass("unreal")) {
                        var elem = $(document.createElement('option'));
                        elem.attr('value', option.key);
                        elem.html(option.value);
                        $(from).append(elem);
                        elems.push(elem);
                    }
                });
                $.each(elems, function (i, elem) { elem.show() });
                $('option:selected', from).each(function (i, option) {
                    $(option).removeAttr('selected');
                });
                if (%(json:has_empty)) {
                    var empty = $('option[class~="empty"]', from).first();
                    empty.attr('selected', 'selected');
                }
                return true;
            !,  sel_root  => $_[0]->_sel_js_root,
                has_empty => $_[0]->_has_empty;
        },
    },
    selected => {
        get => sub {
            return js_code q!
                var sel      = %(json:sel_root);
                var from     = sel ? $(sel, root) : $(root);
                var selected = $(
                    'option:selected',
                    from
                );
                if (%(json:is_multi)) {
                    var keys = [];
                    selected.each(function (i, option) {
                        keys.push(option.attr('value'));
                    });
                    return keys;
                }
                else {
                    return selected.last().val();
                }
            !,  sel_root => $_[0]->_sel_js_root,
                is_multi => $_[0]->_multiple;
        },
        set => sub {
            return js_code q!
                var sel  = %(json:sel_root);
                var from = sel ? $(sel, root) : $(root);
                $('option:selected', from)
                    .each(function (i, option) {
                        $(option).removeAttr('selected');
                    });
                if (%(json:is_multi)) {
                    var keys = {};
                    $.each(value, function (i, key) {
                        keys[key] = true;
                    });
                    $('option:not([class~="unreal"])', from)
                        .each(function (i, option) {
                            if (keys[option.attr("value")]) {
                                $(option).attr("selected", "selected");
                            }
                        });
                }
                else {
                    $('option[value="' + value + '"]', from)
                        .each(function (i, option) {
                            $(option).attr("selected", "selected");
                        });
                }
                return true;
            !,  sel_root => $_[0]->_sel_js_root,
                is_multi => $_[0]->_multiple;
        },
    },
};

sub _sel_js_root { undef }
sub _sel_root    { '.ui-field-select' }

sub _prepare_markup {
    my ($self, $ctx, $markup, $data) = @_;
    my %active;
    my $select_first;
    if (defined( my $selected = $data->{selected} )) {
        if (ref $selected) {
            $active{$_} = 1
                for @$selected;
        }
        else {
            $active{$selected} = 1;
        }
    }
    return $markup
        ->apply($self->_cb_apply_common($self->_sel_root))
        ->apply_if($self->_multiple, sub {
            $_->set_attribute('.ui-field-select', multiple => 'multiple');
        })
        ->apply_if(defined($data->{size}), sub {
            $_->set_attribute('.ui-field-select', size => $data->{size});
        })
        ->replace_content('.ui-field-select', \join '',
            defined($self->_empty_label) ? $self->_blank_option
                ->add_to_attribute('option', class => 'unreal empty')
                ->replace_content('option', $self->_empty_label)
                ->apply_if($self->_empty_hidden, sub {
                  $_->add_to_attribute('option',
                    style => ';display: none;',
                  );
                })
                ->to_html : (),
            $data->{options} ? (map {
                my $option = $_;
                $self->_blank_option
                    ->set_attribute('option', value => $option->{key})
                    ->replace_content('option', $option->{value})
                    ->apply_if($active{$option->{key}}, sub {
                      $_->set_attribute('option', selected => 'selected');
                    })
                    ->to_html;
            } @{$data->{options}}) : (),
        )
        ->memoize;
}

sub _blank_option { HTML::Zoom->from_html('<option></option>') }

with $_ for qw(
    WebLayer::UI::Component::Role::FromTemplate
    WebLayer::UI::Component::Role::WithIdentifier
    WebLayer::UI::Component::Role::WithClasses
    WebLayer::UI::Component::Role::WithEvents::Inputs
);

1;
