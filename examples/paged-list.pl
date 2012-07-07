use strictures 1;
use FindBin;
use WebLayer::UI;
use JSON::XS;

$ENV{WEBLAYER_SHAREDIR} = "$FindBin::Bin/../share";

my $_json = JSON::XS->new;

do {
  package MyApp::View;
  use Moo;

  with 'WebLayer::UI::View::API';

  sub reify {
    my ($self, $ctx) = @_;
    return $ctx->make('Page')
      ->receives(title => 'page.title')
      ->static(
        jquery_uri  => 'page.jquery',
        wlui_js_uri => 'page.wlui',
      )
      ->children(
        $ctx->make('Paragraph')
          ->id('header')
          ->receives(content => 'page.title'),
        $ctx->make('Input::Select')
          ->single
          ->receives(selected => 'list.count_per_page')
          ->provides(selected => 'list.count_per_page')
          ->fixed(options => [
            { key => 10, value => 10 },
            { key => 20, value => 20 },
            { key => 30, value => 30 },
          ]),
      );
  }
};

do {
  package MyApp::Web;
  use Web::Simple;

  my $ui   = WebLayer::UI->new;
  my $view = MyApp::View->new;

  sub dispatch_request {
    my ($self, $env) = @_;
    sub (GET + /js/base) {
      return [
        200,
        ['Content-type', 'text/plain'],
        [$ui->js],
      ];
    },
    sub (GET + /) {
      return $self->render({
        page => {
          title     => 'Paging List Test',
          jquery    => 'http://code.jquery.com/jquery-1.7.2.min.js',
          wlui      => '/js/base',
        },
        list => {
          count_per_page    => 10,
        },
      });
    },
  }

  sub render {
    my ($self, $data) = @_;
    return [
      200,
      ['Content-type', 'text/html'],
      [$ui->render($view, $data)],
    ];
  }

  sub render_json {
    my ($self, $data) = @_;
    return [
      200,
      ['Content-type', 'application/json'],
      [$_json->encode($data)],
    ];
  }
};

MyApp::Web->run_if_script;
