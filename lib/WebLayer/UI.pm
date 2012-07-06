use strictures 1;

package WebLayer::UI;
use Moo;
use FindBin;
use File::Spec;
use File::ShareDir qw( dist_dir );
use WebLayer::UI::Util  qw( :types );
use Class::Load         qw( load_first_existing_class load_class );

use aliased 'WebLayer::UI::Environment::Base', 'BaseEnv';
use aliased 'WebLayer::UI::Context';
use namespace::clean;

my $_sd_env_var = 'WEBLAYER_SHAREDIR';

my $_root = $FindBin::Bin;
my $_file = sub { File::Spec->catfile(@_) };
my $_dir  = sub { File::Spec->catdir(@_) };

has _namespaces => (
    is          => 'ro',
    init_arg    => 'namespaces',
    default     => sub { ['WebLayer::UI::Component'] },
    isa         => isa_ref('ARRAY', q{Attribute 'namespaces'}),
);

has _share_dir => (is => 'lazy');

sub _build__share_dir {
    my ($self) = @_;
    return $ENV{$_sd_env_var}
        if defined $ENV{$_sd_env_var};
    return $_dir->($_root, 'share')
        if  -e $_file->($_root, qw( dist.ini ))
        and -e $_file->($_root, qw( lib WebLayer UI.pm ));
    return dist_dir('WebLayer-UI');
}

sub js {
    my ($self) = @_;
    return $self->slurp('js/preamble.js');
}

sub file { $_file->((shift)->_share_dir, @_) }
sub dir  { $_dir->((shift)->_share_dir, @_) }

sub slurp {
    my ($self, @path) = @_;
    my $file = $self->file(@path);
    open my $fh, '<:utf8', $file
        or die "Unable to read '$file': $!\n";
    return do {
        local $/;
        scalar <$fh>;
    };
}

sub make_special_event {
    my ($self, $type, $name, @args) = @_;
    my $class = join '::', 'WebLayer::UI::Event', $type;
    load_class($class);
    return $class->new_from_values([@args], name => $name, ui => $self);
}

sub make_event {
    my ($self, $name, @args) = @_;
    my $class = 'WebLayer::UI::Event';
    load_class($class);
    return $class->new_from_values([@args], name => $name, ui => $self);
}

sub make_effect {
    my ($self, $type, %arg) = @_;
    my $full_class = join '::', 'WebLayer::UI::Effect', $type;
    load_class($full_class);
    return $full_class->new(%arg, ui => $self);
}

sub make_action {
    my ($self, $class, $event, @args) = @_;
    my $full_class = join '::', 'WebLayer::UI::Action', $class;
    load_class($full_class);
    return $full_class->new_from_values(
        [@args],
        ui              => $self,
        continue_source => $event,
    );
}

sub make {
    my ($self, $name) = @_;
    return load_first_existing_class(map {
        join '::', $_, $name;
    } @{ $self->_namespaces })->new(ui => $self);
}

sub render {
    my ($self, $view, $data) = @_;
    $data = {}
        unless defined $data;
#    my $env  = BaseEnv->new(data => $data);
    my $ctx  = Context->new(ui => $self, data => $data);
    my $tree = $view->reify($ctx);
    return $ctx->_render($tree)->to_html;
}

1;
