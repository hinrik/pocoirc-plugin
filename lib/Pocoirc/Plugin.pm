package Pocoirc::Plugin;

use 5.010;
use Any::Moose;
use Any::Moose '::Exporter';
use namespace::clean -except => 'meta';

any_moose('::Exporter')->setup_import_methods(
    also  => any_moose(),
    as_is => [qw(depends_on)],
);

sub init_meta {
    my ($class, %args) = @_;

    any_moose()->init_meta(
        for_class  => $args{for_class},
        base_class => 'Pocoirc::Plugin::Object',
    );

    eval qq<
        package $args{for_class};
        use Any::Moose;
        use POE::Component::IRC::Plugin qw(:ALL);
    >;

    return;
}

sub depends_on {
    my ($meta, @plugins) = (caller->meta, @_);
    $meta->add_method('_build__dependencies', sub { [@plugins] });
    return;
}

1;

=encoding utf8

=head1 NAME

Pocoirc::Plugin - Moose (or Mouse) sugar for PoCo-IRC plugins

=head1 SYNOPSIS

 package MyPlugin;

 use Pocoirc::Plugin;

 depends_on('POE::Component::IRC::Plugin::BotAddressed');

 sub S_bot_addressed {
     my ($self, $irc) = splice @_, 0, 2;
     my $msg = ${ $_[2] };

     # deal with public messages...

     return PCI_EAT_NONE;
 }


 # and now with a POE session, courtesy of MooseX::POE/MouseX::POE
 package MyPluginWithPOE;

 use Pocoirc::Plugin;
 with any_moose('X::POE::Role');

 sub START {
     # do something with our session
 }

 sub S_public {
     my ($self, $irc) = splice @_, 0, 2;
     my $msg = ${ $_[2] };

     # deal with public messages...

     return PCI_EAT_NONE;
 }

=head1 DESCRIPTION

This is a module which uses Moose (or Mouse) to simplify PoCo-IRC plugin
writing. It will automatically register any plugin event handlers for you.

L<POE::Component::IRC::Plugin|POE::Component::IRC::Plugin> and
L<Any::Moose|Any::Moose> are automatically L<C<use>|perlfunc>d in your
package, giving you all the plugin handler constants as well as the
L<C<any_moose>|Any::Moose/COMPLEX USAGE> function to help with loading
Moose/Mouse modules.

=head1 ATTRIBUTES

=head2 C<add_args>

This attribute is a hash reference, where the keys are stringified IRC
component objects, and the values are array references containing any
any plugin arguments passed to C<< $irc->plugin_add() >>.

=head1 METHODS

=head2 C<ADD>

This is method is called on your object whenever the plugin is added to an
IRC component (with C<< $irc->plugin_add >>). First argument is the IRC
component. Any extra arguments come from whoever added the plugin to the IRC
component (also retrievable afterward with L<C<add_args>|/add_args>).

Kind of like C<PCI_register> in classic POE::Component::IRC plugins.

=head2 C<DEL>

This is method is called on your object whenever the plugin is deleted form
IRC component (with C<< $irc->plugin_del >>). First argument is the IRC
component. Any extra arguments come from whoever added the plugin to the IRC
component. Kind of like C<PCI_unregister> in classic POE::Component::IRC
plugins.

=head1 FUNCTIONS

=head2 C<depends_on>

Use this function to declare dependencies on other plugins. Takes a list of
plugin class names.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

Kudos to Chris Prather for his Adam bot framework, on which this distribution
is based.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
