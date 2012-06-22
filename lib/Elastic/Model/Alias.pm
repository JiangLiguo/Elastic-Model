package Elastic::Model::Alias;

use Carp;
use Moose;
with 'Elastic::Model::Role::Index';

use namespace::autoclean;

no Moose;

#===================================
sub to {
#===================================
    my $self    = shift;

    my $name    = $self->name;
    my $es      = $self->es;
    my %indices = ( (
            map { $_ => { remove => { index => $_, alias => $name } } }
                keys %{ $es->get_aliases( index => $name ) }
        ),
        $self->_add_aliases(@_)
    );

    $es->aliases( actions => [ values %indices ] );
    $self->model->domain($name)->clear_default_routing;
    $self->model->clear_domain_namespace;
    return $self;
}

#===================================
sub add {
#===================================
    my $self    = shift;
    my %indices = $self->_add_aliases(@_);
    $self->es->aliases( actions => [ values %indices ] );
    $self->model->domain( $self->name )->clear_default_routing;
    return $self;
}

#===================================
sub remove {
#===================================
    my $self    = shift;
    my $name    = $self->name;
    my @actions = map { { remove => { index => $_, alias => $name } } } @_;
    $self->es->aliases( actions => \@actions );
    $self->model->clear_domain_namespace;
    return $self;
}

#===================================
sub aliased_to {
#===================================
    my $self    = shift;
    my $name    = $self->name;
    my $indices = $self->es->get_aliases( index => $name );
    croak "($name) is an index, not an alias"
        if $indices->{$name};

    +{ map { $_ => $indices->{$_}{aliases}{$name} } keys %$indices };
}

#===================================
sub _add_aliases {
#===================================
    my $self = shift;
    my $name = $self->name;
    my $es   = $self->es;
    my %indices;

    while (@_) {
        my $index  = shift @_;
        my %params = (
            ref $_[0] ? %{ shift @_ } : (),
            index => $index,
            alias => $name
        );
        if ( my $filter = delete $params{filterb} ) {
            $params{filter} = $es->builder->filter($filter)->{filter};
        }
        $indices{$index} = { add => \%params };
    }
    return %indices;
}

1;

__END__

# ABSTRACT: Administer aliases in ElasticSearch

=head1 SYNOPSIS

    $alias = $model->namespace('myapp')->alias;
    $alias = $model->namespace('myapp')->alias('alias_name');

    $alias->to( 'index_1', 'index_2' );
    $alias->to( 'index_1' => \%settings, index_2 => \%settings);

    $alias->add( 'index_1', 'index_2' );
    $alias->add( 'index_1' => \%settings, index_2 => \%settings);

    $alias->remove( 'index_1', 'index_2' );

    \%indices = $alias->aliased_to;

=head1 CONSUMES

L<Elastic::Model::Role::Index>

=head1 DESCRIPTION

L<Elastic::Model::Alias> objects are used to create and administer
L<index aliases|Elastic::Manual::Terminology/Alias> in an ElasticSearch cluster.

See L<Elastic::Manual::Scaling> for more about how aliases can be used in your
application.

=head1 METHODS

=head2 to()

    $alias = $alias->to(@index_names);
    $alias = $alias->to(
        index_name => \%alias_settings,
        ...
    );

Creates or updates the alias L</name> and sets it to point
to the listed indices.  If it already exists and points to indices not specified
in C<@index_names>, then those indices will be removed from the alias.

You can delete an alias completely with:

    $alias->to();

Aliases can have filters and routing values associated with an index, for
instance:

    $alias->to(
        my_index => {
            routing => 'client_one',
            filterb => { client => 'client_one'}
        }
    );

See L<Elastic::Manual::Scaling> for more about these options.

=head2 add()

    $alias = $alias->add(@index_names);
    $alias = $alias->add(
        index_name => \%alias_settings,
        ...
    );

L</add()> works in the same way as L</to()> except that
indices are only added - existing indices are not removed.

=head2 remove()

    $alias = $alias->remove(@index_names);

The listed index names are removed from alias L</name>.

=head2 aliased_to()

    $indices = $alias->aliased_to();

Returns a hashref of the current settings for an alias, suitable for passing to
L</to()>. The keys are index names, and the values are the alias settings.


=head1 IMPORTED ATTRIBUTES

=head2 namespace

See L<Elastic::Model::Role::Index/namespace>

=head2 name

See L<Elastic::Model::Role::Index/name>

=head1 IMPORTED METHODS

=head2 close()

See L<Elastic::Model::Role::Index/close()>

=head2 open()

See L<Elastic::Model::Role::Index/open()>

=head2 refresh()

See L<Elastic::Model::Role::Index/refresh()>

=head2 delete()

See L<Elastic::Model::Role::Index/delete()>

=head2 update_analyzers()

See L<Elastic::Model::Role::Index/update_analyzers()>

=head2 update_settings()

See L<Elastic::Model::Role::Index/update_settings()>

=head2 delete_mapping()

See L<Elastic::Model::Role::Index/delete_mapping()>

=head2  is_alias()

See L<Elastic::Model::Role::Index/is_alias()>

=head2 is_index()

See L<Elastic::Model::Role::Index/is_index()>

=head1 SEE ALSO

=over

=item *

L<Elastic::Model::Role::Index>

=item *

L<Elastic::Model::Index>

=item *

L<Elastic::Model::Namespace>

=item *

L<Elastic::Manual::Scaling>

=back
