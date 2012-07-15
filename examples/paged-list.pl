use strictures 1;
use FindBin;
use WebLayer::UI;
use JSON::XS;

$ENV{WEBLAYER_SHAREDIR} = "$FindBin::Bin/../share";

my $_json = JSON::XS->new->relaxed->utf8;

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
      ->variable('list.page')
      ->variable('list.next_page')
      ->variable('list.prev_page')
      ->variable('list.first_page')
      ->variable('list.last_page')
      ->children(
        $ctx->make('Paragraph')
          ->id('header')
          ->receives(content => 'page.title'),
        $self->_reify_pager($ctx),
        $self->_reify_list($ctx),
        $self->_reify_pager($ctx),
      );
  }

  sub _reify_pager {
    my ($self, $ctx) = @_;
    return $ctx->make('Paragraph')->children(
      $self->_reify_page_link($ctx, 'list.first_page', 'First Page'),
      ' - ',
      $self->_reify_page_link($ctx, 'list.prev_page', 'Previous Page'),
      ' - ',
      $self->_reify_position($ctx),
      ' - ',
      $self->_reify_page_link($ctx, 'list.next_page', 'Next Page'),
      ' - ',
      $self->_reify_page_link($ctx, 'list.last_page', 'Last Page'),
    ),
  }

  sub _reify_page_link {
    my ($self, $ctx, $source, $title) = @_;
    return $ctx->make('Switchable::Bool')
      ->receives(state => $source)
      ->case_false($ctx->make('Segment')->fixed(text => $title))
      ->case_true(
        $ctx->make('Link')
          ->fixed(text => $title)
          ->on(click => sub {
            $_->perform('Request' => sub {
              $_->send_to('/api/page')
                ->send_method('GET')
                ->send_aliased($source => 'list.page')
                ->when_success(sub {
                  $_->populate(qw(
                    list.next_page
                    list.prev_page
                    list.page
                    list.all
                  ));
                })
              })
              ->stop_event;
          }),
      );
  }

  sub _reify_position {
    my ($self, $ctx) = @_;
    return $ctx->make('Segment')->children(
      $ctx->make('Segment')->receives(content => 'list.page'),
      '/',
      $ctx->make('Segment')->receives(content => 'list.last_page'),
    );
  }

  sub _reify_list {
    my ($self, $ctx) = @_;
    return $ctx->make('List')
      ->unordered
      ->receives(all => 'list.all')
      ->collection(sub {
        $_->keyed_by('id')
          ->contains(
            id      => 'user.id',
            name    => 'user.name',
            city    => 'user.city',
          );
      })
      ->prototype(
        $ctx->make('Segment')->variable('user.id')->children(
          $ctx->make('Segment')->receives(content => 'user.name'),
          ' lives in ',
          $ctx->make('Segment')->receives(content => 'user.city'),
          '.',
        ),
      );
  }
};

do {
  package MyApp::Web;
  use Web::Simple;
  use Data::Faker;
  use Data::Page;

  my $ui   = WebLayer::UI->new;
  my $view = MyApp::View->new;
  my $fake = Data::Faker->new;

  my $user_id = 476;
  my @users = map {
      { id => $user_id++, name => $fake->name, city => $fake->city };
  } 1 .. 100;

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
        %{ $self->get_page },
      });
    },
    sub (GET + /api/page + ?list.page=) {
      my ($self, $page) = @_;
      return $self->render_json($self->get_page(
        current_page => $page,
      ));
    },
  }

  sub get_page {
      my ($self, %arg) = @_;
      my $count_per_page = $arg{count_per_page} || 10;
      my $current_page   = $arg{current_page} || 1;
      my $page = Data::Page->new;
      $page->total_entries(scalar @users);
      $page->entries_per_page($count_per_page);
      $page->current_page($current_page);
      return +{
          list => {
              count_per_page    => $count_per_page,
              page              => $current_page,
              all               => [$page->splice([@users])],
              last_page         => $page->last_page,
              next_page         => $page->next_page,
              prev_page         => $page->previous_page,
              first_page        => $page->first_page,
              last_page         => $page->last_page,
          },
      };
  }

  sub render {
    my ($self, $data) = @_;
    return [
      200,
      ['Content-type', 'text/html; charset=UTF-8'],
      [$ui->render($view, $data)],
    ];
  }

  sub render_json {
    my ($self, $data) = @_;
    return [
      200,
      ['Content-type', 'application/json; charset=UTF-8'],
      [$_json->encode($data)],
    ];
  }
};

MyApp::Web->run_if_script;
