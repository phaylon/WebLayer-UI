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
        $self->_reify_welcome_message($ctx),
        $self->_reify_dialog($ctx),
      );
  }

  sub _reify_welcome_message {
    my ($self, $ctx) = @_;
    return $ctx->make('Paragraph')
      ->id('welcome-message')
      ->receives(content => 'login.welcome')
      ->hidden;
  }

  sub _reify_dialog {
    my ($self, $ctx) = @_;
    return $ctx->make('Dialog::Simple')
      ->id('loginbox-form')
      ->static(submit_to => 'login.submit.uri')
      ->provides(submit_to => 'login.submit.uri')
      ->fixed(submit_method => 'POST')
      ->on(submit => sub {
        $_->perform('Request', sub {
          $_->send_method('POST')
            ->send_to('/api')
            ->send_values('login.username', 'login.password')
            ->when_success(sub {
              $_->when_false('login.ok', sub {
                  $_->populate(qw(
                    login.message
                    login.password
                  ));
                })
                ->when_true('login.ok', sub {
                  $_->populate(qw( login.welcome ))
                    ->effect('Hide', sub {
                      $_->targets('#loginbox-form')
                        ->duration('fast')
                        ->then(sub {
                          $_->effect('Show', sub {
                              $_->targets('#welcome-message')
                                ->duration('fast');
                            })
                            ->perform('Remove', sub {
                              $_->targets('#loginbox-form');
                            });
                        });
                    });
                });
            });
        })
        ->stop_event;
      })
      ->field(Text => sub {
        $_->receives(value => 'login.username')
          ->provides(value => 'login.username')
          ->fixed(label => 'Username')
          ->receives(message => 'login.message')
      })
      ->field(Password => sub {
        $_->receives(value => 'login.password')
          ->provides(value => 'login.password')
          ->fixed(label => 'Password')
      })
      ->children($ctx->make('Box')->id('actions')->children(
        $ctx->make('Form::Submit')
            ->fixed(label => 'OK'),
      ));
  }
};

do {
  package MyApp::Web;
  use Web::Simple;

  my $ui   = WebLayer::UI->new;
  my $view = MyApp::View->new;

  my %passwd = (foo => 'bar', baz => 'qux');

  sub dispatch_request {
    my ($self, $env) = @_;
    sub (GET + /js/base) {
      return [
        200,
        ['Content-type', 'text/plain'],
        [$ui->js],
      ];
    },
    sub (POST + /api + %login.username~ &login.password~) {
      my ($self, $user, $pass) = @_;
      if (my $pw = $passwd{$user}) {
        if ($pass eq $pw) {
          return $self->render_json({
            'login.ok' => 1,
            'login.welcome' => "Welcome, $user!",
          });
        }
      }
      return $self->render_json({
        'login.message'  => 'Invalid username or password',
        'login.password' => '',
      });
    },
    sub (/) {
      return $self->render({
        page => {
          title     => 'Login Test',
          jquery    => 'http://code.jquery.com/jquery-1.7.2.min.js',
          wlui      => '/js/base',
        },
        login => {
          submit => {
            method  => 'POST',
            uri     => '/',
          },
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
