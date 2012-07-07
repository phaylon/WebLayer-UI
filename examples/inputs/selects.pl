use strictures 1;
use FindBin;
use WebLayer::UI;
use JSON::XS;

$ENV{WEBLAYER_SHAREDIR} ||= "$FindBin::Bin/../../share";

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
        $ctx->make('Header')->id('page-header')->children(
          $ctx->make('Paragraph')
            ->id('header')
            ->receives(content => 'page.title'),
        ),
        map {
          my ($title, @body) = @$_;
          $ctx->make('Section')->classes('demo-section')->children(
            $ctx->make('Header')->children(
              $ctx->make('Heading')
                ->level(1)
                ->fixed(content => $title),
            ),
            @body,
          );
        } $self->_sections($ctx),
      );
  }

  sub _sections {
    my ($self, $ctx) = @_;
    return(
      $self->_section_basic_single($ctx),
      $self->_section_basic_multi($ctx),
      $self->_section_sequential($ctx),
    );
  }

  sub _section_sequential {
    my ($self, $ctx) = @_;
    return [
      'Sequential Loading',
      $self->_comment($ctx, 'Make a selection for more restrictions:'),
      $ctx->make('Paragraph')->children(
        $ctx->make('Input::Select')
          ->empty('[Select a letter]')
          ->hide_empty
          ->static(options => 'sequential.letters')
          ->provides(selected => 'sequential.current_letter')
          ->on(change => sub {
              $_->perform('Request', sub {
                  $_->send_method('GET')
                    ->send_to('/users_by_letter')
                    ->send_values('sequential.current_letter')
                    ->when_success(sub {
                      $_->populate('sequential.users')
                        ->effect('Show', sub {
                          $_->targets('#seq-users')
                            ->duration('fast');
                        })
                    })
                })
                ->effect('Hide', sub {
                  $_->targets('#seq-info')
                    ->duration('fast');
                });
          }),
        $ctx->make('Input::Select')
          ->empty('[Select a user]')
          ->hide_empty
          ->hidden
          ->id('seq-users')
          ->receives(options => 'sequential.users')
          ->provides(selected => 'sequential.current_user')
          ->on(change => sub {
              $_->perform('Request', sub {
                  $_->send_method('GET')
                    ->send_to('/user_info')
                    ->send_values('sequential.current_user')
                    ->when_success(sub {
                      $_->populate('sequential.user', 'sequential.city')
                        ->effect('Show', sub {
                          $_->targets('#seq-info')
                            ->duration('fast');
                        })
                    })
                });
          }),
        $ctx->make('Segment')->hidden->id('seq-info')->children(
          'The user ',
          $ctx->make('Segment')->receives(text => 'sequential.user'),
          ' lives in ',
          $ctx->make('Segment')->receives(text => 'sequential.city'),
          '.',
        ),
      ),
    ];
  }

  sub _section_basic_multi {
    my ($self, $ctx) = @_;
    return [
      'Basic Multi Select',
      $self->_comment($ctx, 'Without an empty entry:'),
      $self->_basic($ctx)
        ->multiple
        ->fixed(size => 4),
      $self->_comment($ctx, 'With an empty entry:'),
      $self->_basic($ctx)
        ->multiple
        ->empty('[No weekday]')
        ->fixed(size => 4),
      $self->_comment($ctx, 'With adjustable size:'),
      $ctx->make('Paragraph')
        ->children(
          'Currently displaying ',
          $ctx->make('Segment')
            ->receives(content => 'adjustable_size.size'),
          ' entries at once',
        ),
      $ctx->make('Input::Select')
        ->provides(selected => 'adjustable_size.new')
        ->static(selected => 'adjustable_size.size')
        ->on(change => sub {
          $_->sync('adjustable_size.new' => 'adjustable_size.size')
            ->continue_event;
        })
        ->fixed(options => [
          map {
            { key => $_, value => "Show $_" };
          } 1 .. 7,
        ]),
      $self->_basic($ctx)
        ->multiple
        ->receives(size => 'adjustable_size.size')
    ];
  }

  sub _section_basic_single {
    my ($self, $ctx) = @_;
    return [
      'Basic Single Select',
      $self->_comment($ctx, 'Without a selectable empty option:'),
      $self->_basic($ctx)
        ->empty('[Select a weekday]')
        ->hide_empty,
      $self->_comment($ctx, 'With a selectable empty option:'),
      $self->_basic($ctx)
        ->empty('[Select a weekday]'),
    ];
  }

  sub _comment {
    my ($self, $ctx, $comment) = @_;
    return $ctx->make('Paragraph')
        ->classes('comment')
        ->fixed(content => $comment);
  }

  sub _basic {
    my ($self, $ctx) = @_;
    return $ctx->make('Input::Select')
      ->fixed(options => [
        { key => 0, value => 'Monday' },
        { key => 1, value => 'Tuesday' },
        { key => 2, value => 'Wednesday' },
        { key => 3, value => 'Thursday' },
        { key => 4, value => 'Friday' },
        { key => 5, value => 'Saturday' },
        { key => 6, value => 'Sunday' },
      ]);
  }
};

do {
  package MyApp::Web;
  use Web::Simple;
  use Data::Faker;

  my $faker = Data::Faker->new;

  my @users = sort { $a->{name} cmp $b->{name} } map {
    { id => $_, name => $faker->name, city => $faker->city };
  } 1 .. 50;
  my %by_id = (map { ($_->{id}, $_) } @users);

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
      my %letters;
      m{^(.)}, $letters{uc $1}++
        for map { $_->{name} } @users;
      return $self->render({
        page => {
          title     => 'Select Inputs',
          jquery    => 'http://code.jquery.com/jquery-1.7.2.min.js',
          wlui      => '/js/base',
        },
        adjustable_size => {
          size      => 3,
        },
        sequential => {
          letters => [ map {
            { key => $_, value => $_ };
          } sort keys %letters ],
        },
      });
    },
    sub (GET + /users_by_letter + ?*) {
      my ($self, $params) = @_;
      my $letter = $params->{'sequential.current_letter'};
      return $self->render_json({
        'sequential.users' => [ map {
          { key => $_->{id}, value => $_->{name} };
        } grep { $_->{name} =~ m{^\Q$letter\E} } @users ],
      });
    },
    sub (GET + /user_info + ?*) {
      my ($self, $params) = @_;
      my $user = $params->{'sequential.current_user'};
      return $self->render_json({
        'sequential.user' => $by_id{$user}{name},
        'sequential.city' => $by_id{$user}{city},
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
