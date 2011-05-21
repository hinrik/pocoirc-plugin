use strict;
use warnings FATAL => 'all';
use POE;
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 6;

#{
#    package FooRole;
#    use Any::Moose '::Role';
#
#    sub bar { }
#}

{
    package MyPlugin;
    use Test::More;

    use Pocoirc::Plugin;
#    with 'FooRole';

    has foo => (
        isa => 'Str',
        is => 'rw',
    );

    sub ADD {
        my ($self, $irc, @args) = @_;
        pass('Got ADD');
        return 1;
    }

    sub S_join {
        my ($self, $irc) = splice @_, 0, 2;
        pass('Got S_join');
        is($self->add_args->{$irc}{hlagh}, 'yes', 'Correct add_args');
        is($self->foo, 'bar', 'Got the right argument');
        return PCI_EAT_NONE;
    }
}

my $bot = POE::Component::IRC->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);
$bot->plugin_add(
    'MyPlugin',
    MyPlugin->new(
        foo => 'bar',
    ),
    hlagh => 'yes',
);

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_join
            irc_disconnected
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel) = $_[KERNEL];

    $ircd->yield('register', 'all');
    $ircd->yield('add_listener');
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub ircd_listener_failure {
    my ($kernel, $op, $reason) = @_[KERNEL, ARG1, ARG3];
    $kernel->yield('_shutdown', "$op: $reason");
}

sub ircd_listener_add {
    my ($kernel, $port) = @_[KERNEL, ARG0];

    $bot->yield(register => 'all');
    $bot->yield(connect => {
        nick    => 'TestBot1',
        server  => '127.0.0.1',
        port    => $port,
    });
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass('Logged in');
    $irc->yield('join', '#testchannel');
}

sub irc_join {
    my ($sender, $heap, $where) = @_[SENDER, HEAP, ARG1];
    my $irc = $sender->get_heap();
#    my $plugin = $irc->plugin_by_role('FooRole');
#    ok($plugin->isa('MyPlugin'), 'Found plugin by role');
    $irc->yield('quit');
}

sub irc_disconnected {
    my ($kernel) = $_[KERNEL];
    pass('irc_disconnected');
    $kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $bot->yield('shutdown');
    $ircd->yield('shutdown');
}
