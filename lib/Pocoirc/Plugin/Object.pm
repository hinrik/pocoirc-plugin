package Pocoirc::Plugin::Object;

use 5.010;
use Any::Moose;
use List::Util 'first';
use namespace::clean -except => 'meta';

has _dependencies => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
);

# might get overriden by 'depends_on' which Pocoirc::Plugin exports
sub _build__dependencies { return [] }

has add_args => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef]',
    default => sub { {} },
);

sub PCI_register {
    my ($self, $irc, %args) = @_;

    my $add_args = $self->add_args;
    $add_args->{$irc} = \%args;

    my $deps = $self->_dependencies;
    my @plugins = values %{ $irc->plugin_list };
    my @missing = grep { my $dep = $_; !first { $_->isa($dep) } @plugins } @$deps;
    if (@missing) {
        die ref($self)." needs the following plugins to be loaded:\n"
            . join('', map { "  $_\n" } @missing);
    }

    $self->ADD($irc, %args) if $self->can('ADD');

    my @events = grep { /^[SU]_\w+/ } $self->meta->get_all_method_names;
    my @s_events = map { s/^S_//; $_ } grep { /^S_/ } @events;
    my @u_events = map { s/^U_//; $_ } grep { /^U_/ } @events;
    $irc->plugin_register($self, 'SERVER', @s_events) if @s_events;
    $irc->plugin_register($self, 'USER', @u_events) if @u_events;

    return 1;
};

sub PCI_unregister {
    my ($self, $irc, @args) = @_;

    my $add_args = $self->add_args;
    delete $add_args->{$irc};
    $self->DEL($irc, @args) if $self->can('DEL');
    return 1;
};

1;

=encoding utf8

=head1 NAME

Pocoirc::Plugin::Object - Base class for Pocoirc::Plugin

=cut
