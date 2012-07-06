package WebLayer::UI::Component::Dialog::Simple::Field::Password;
use Moo;
use namespace::clean;

extends 'WebLayer::UI::Component::Input::Password';

sub _default_template { 'dialog/simple/field/text.html' }

sub _sel_js_root { '.ui-field-text' }
sub _sel_root    { '.ui-dialog-simple-row' }

with $_ for qw(
    WebLayer::UI::Component::Dialog::Simple::Field::API
);

1;
