package WebLayer::UI::Component::Dialog::Simple;
use Moo;
use HTML::Zoom;
use namespace::clean;

extends 'WebLayer::UI::Component::Form';

sub _default_template { 'dialog/simple.html' }

sub _sel_container { '.ui-dialog-table' }

sub field {
    my ($self, $type, $cb_init) = @_;
    my $field = $self->_ui->make("Dialog::Simple::Field::$type");
    $self->children(do {
        local $_ = $field;
        $cb_init->();
    });
    return $self;
}

around _render_child => sub {
    my ($orig, $self, $ctx, $child) = @_;
    my $child_markup = $self->$orig($ctx, $child);
    return $child_markup
        if $child
            ->does('WebLayer::UI::Component::Dialog::Simple::Field::API');
    return HTML::Zoom
        ->from_file($ctx->file('templates/dialog/simple/non-field.html'))
        ->replace_content('.ui-non-field', $child_markup)
        ->memoize;
};

1;
