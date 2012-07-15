use strictures 1;

package WebLayer::UI::Util;
use Data::Dump;
use Scalar::Util                qw( blessed );
use Hash::Merge                 qw( merge );
use Carp                        qw( confess );
use JSON::XS;
use JavaScript::Minifier::XS    qw( minify );
use Sub::Install                qw( install_sub );
use Method::Generate::Accessor;
use namespace::clean;

use Sub::Exporter -setup => {
    exports => [qw(
        isa_ref isa_instance isa_component isa_duration
        pp
        nest_data unnest_data get_nested
        js_get_attr js_set_attr
        js_get_text js_set_text
        js_get_html js_set_html
        js_code
        js_get js_set
        json_enc json_dec
        singleline tight_singleline
        dbg_pp
        settable collectable mappable
    )],
    groups => {
        js => [qw(
            json_enc json_dec
            js_get_attr js_set_attr
            js_get_text js_set_text
            js_get_html js_set_html
            js_code
            js_get js_set
        )],
        json => [qw(
            json_enc json_dec
        )],
        types => [qw(
            isa_ref isa_instance isa_component isa_duration
        )],
        nested => [qw(
            nest_data unnest_data get_nested
        )],
        strings => [qw(
            singleline tight_singleline
        )],
        debug => [qw(
            dbg_pp pp
        )],
        api => [qw(
            settable collectable mappable
        )],
    },
};

sub js_set {
    my ($name, $value_expr) = @_;
    return sprintf 'wlui.set(current, %s, %s)',
        json_enc($name),
        $value_expr;
}

sub js_get {
    my ($name) = @_;
    return sprintf 'wlui.get(current, %s)',
        json_enc($name);
}

my $_meth_gen = Method::Generate::Accessor->new;

sub mappable {
    my ($name, %arg) = @_;
    my $class = scalar caller;
    my $attr  = "_${name}_ref";
    install_sub {
        into    => $class,
        as      => "_has_$name",
        code    => sub { scalar keys %{ $_[0]->$attr } },
    };
    install_sub {
        into    => $class,
        as      => "_${name}_kv",
        code    => sub { %{ $_[0]->$attr } },
    };
    install_sub {
        into    => $class,
        as      => $name,
        code    => sub {
            my $ref = $_[0]->$attr;
            %$ref = (%$ref, @_[1 .. $#_]);
            return $_[0];
        },
    };
    if (defined( my $clear = $arg{clearer} )) {
        install_sub {
            into    => $class,
            as      => $clear,
            code    => sub { %{ $_[0]->$attr } = (); $_[0] },
        };
    }
    return $attr => (
        is      => 'ro',
        default => sub { {} },
        %arg,
    );
}

sub collectable {
    my ($name, %arg) = @_;
    my $class = scalar caller;
    my $attr  = "_${name}_ref";
    my $list  = "_${name}";
    install_sub {
        into    => $class,
        as      => $list,
        code    => sub { @{ $_[0]->$attr } },
    };
    install_sub {
        into    => $class,
        as      => $name,
        code    => sub { push @{ $_[0]->$attr }, @_[1 .. $#_]; $_[0] },
    };
    install_sub {
        into    => $class,
        as      => "_has_$name",
        code    => sub { scalar @{ $_[0]->$attr } },
    };
    if (defined( my $clear = $arg{clearer} )) {
        install_sub {
            into    => $class,
            as      => $clear,
            code    => sub { @{ $_[0]->$attr } = (); $_[0] },
        };
    }
    return $attr => (
        is      => 'ro',
        default => sub { [] },
        %arg,
    );
}

sub settable {
    my ($name, %arg) = @_;
    my $class = scalar caller;
    my $attr  = "_$name";
    my $write = "_set_$name";
    install_sub {
        into    => $class,
        as      => $name,
        code    => sub { $_[0]->$write($_[1]); $_[0] },
    };
    install_sub {
        into    => $class,
        as      => "_has_$name",
        code    => sub { defined $_[0]->$attr },
    };
    if (defined( my $clear = $arg{clearer} )) {
        my $raw_clearer = $arg{clearer} = "_clear_$name";
        install_sub {
            into    => $class,
            as      => $clear,
            code    => sub { $_[0]->$raw_clearer; $_[0] },
        };
    }
    return $attr => (
        is      => 'ro',
        writer  => $write,
        %arg,
    );
}

sub dbg_pp {
    pp(\[@_]);
    return wantarray ? @_ : shift;
}

sub tight_singleline ($) {
    my $str = shift;
    $str =~ s{\s*\n+\s*}{}g;
    $str =~ s{(?:^\s+|\s+$)}{}g;
    return $str;
}

sub singleline ($) {
    my $str = shift;
    $str =~ s{\s*\n+\s*}{ }g;
    $str =~ s{(?:^\s+|\s+$)}{}g;
    return $str;
}

my $_json = JSON::XS->new->allow_nonref->utf8;

sub json_enc { $_json->encode(shift) }
sub json_dec { $_json->decode(shift) }

my $_opt_select = sub {
    my $sel = shift;
    return '' unless defined $sel;
    sprintf '%s, ', json_enc $sel;
};

sub js_code {
    my ($body, %arg) = @_;
    $body = singleline $body;
    $body =~ s!\%\(json:([a-z0-9_]+)\)!json_enc($arg{$1})!gie;
    $body =~ s!\%\(raw:([a-z0-9_]+)\)!$arg{$1}!gie;
    return minify $body;
}

sub js_get_html {
    return sprintf q!return $(%sroot).html()!, $_opt_select->(shift);
}

sub js_set_html {
    return sprintf q!$(%sroot).html(%s); return true!,
        $_opt_select->($_[0]),
        $_[1];
}

sub js_get_text {
    return sprintf q!return $(%sroot).text()!, $_opt_select->(shift);
}

sub js_set_text {
    return sprintf q!$(%sroot).text(%s); return true!,
        $_opt_select->($_[0]),
        $_[1];
}

sub js_get_attr {
    return sprintf q!return $(%sroot).attr(%s)!,
        $_opt_select->($_[0]),
        json_enc($_[1]);
}

sub js_set_attr {
    my ($sel, $attr, $value_expr) = @_;
    return sprintf q!$(%sroot).attr(%s, %s); return true!,
        $_opt_select->($sel),
        json_enc($attr),
        $value_expr;
}

sub get_nested {
    my ($data, $name) = @_;
    my @parts = split m{\.}, $name;
    my @done;
    for my $key (@parts) {
        return undef
            unless defined $data;
        push @done, $key;
#        if ($key =~ m{^\[(\d+)\]$}) {
#            my $index = $1;
#            confess sprintf q{Cannot access index %d of non-array at %s},
#                $index, join '.', @done
#                unless ref $data eq 'ARRAY';
#            $data = $data->[$index];
#        }
#        else {
            confess sprintf q{Cannot access key '%s' of non-hash at %s},
                $key, join '.', @done
                unless ref $data eq 'HASH';
            $data = $data->{$key};
#        }
    }
    return $data;
}

sub nest_data {
    my ($data, $prefix) = @_;
    my $descend_prefix = defined($prefix) ? "$prefix." : '';
    if (ref $data eq 'HASH') {
        my $done = {};
        %$done = (
            %$done,
            %{ nest_data($data->{$_}, $descend_prefix . $_) },
        ) for keys %$data;
        return $done;
    }
#    elsif (ref $data eq 'ARRAY') {
#        my $done = {};
#        %$done = (
#            %$done,
#            %{ nest_data($data->[$_], $descend_prefix . "[$_]") },
#        ) for 0 .. $#$data;
#        return $done;
#    }
    else {
        return { $prefix => $data };
    }
}

sub unnest_data {
    my ($data) = @_;
    my %done;
    my %deeper;
    for my $key (keys %$data) {
        if ($key =~ m{^([^.]+)\.(.+)$}) {
            $deeper{$1}{$2} = $data->{$key};
        }
        else {
            $done{$key} = $data->{$key};
        }
    }
#    my %count;
#    $count{$_}++ for map {
#        m{^\[\d+\]$} ? 'array' : 'hash';
#    } keys(%done), keys(%deeper);
#    confess "Cannot mix array and hash data structures"
#        if $count{hash} and $count{array};
#    if ($count{hash}) {
        return +{ %done, map {
            ($_, unnest_data($deeper{$_}));
        } keys %deeper };
#    }
#    elsif ($count{array}) {
#        my @processed;
#        for my $key (keys %done) {
#            $key =~ m{^\[(\d+)\]$};
#            $processed[$1] = $done{$key};
#        }
#        for my $key (keys %deeper) {
#            $key =~ m{^\[(\d+)\]$};
#            $processed[$1] = unnest_data($deeper{$key});
#        }
#        return [@processed];
#    }
#    else {
#        return {};
#    }
}

sub pp { Data::Dump::pp(shift) }

sub isa_ref {
    my ($type, $name) = @_;
    return sub {
        ref($_[0]) eq $type
            or confess("$name has to be a $type reference");
    };
}

sub isa_instance {
    my ($class, $name) = @_;
    return sub {
        blessed($_[0]) and $_[0]->isa($class)
            or confess("$name has to be an instance of $class");
    };
}

sub isa_component {
    my ($name) = @_;
    return isa_instance('WebLayer::UI::Component', $name);
}

sub isa_duration {
    my ($name) = @_;
    return sub {
        confess("$name has to be 'fast', 'slow' or a millisecond value")
            if not(defined $_[0])
            or ref($_[0])
            or $_[0] eq 'fast'
            or $_[0] eq 'slow'
            or $_[0] =~ m{^[0-9]+$};
    };
}

1;
