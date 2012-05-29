#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;
use Test::Exception;

use lib 't/lib';

BEGIN {
    use_ok 'TypeTest' || print 'Bail out';
}

our ( $test_class, @mapping );

my $model = new_ok 'TypeTest';
isa_ok my $tm = $model->type_map, 'Elastic::Model::TypeMap::Base';

note "Mapping for $test_class";

does_ok my $class = $model->class_for($test_class),
    'Elastic::Model::Role::Doc';

my $meta = $class->meta;
while (@mapping) {
    test_mapping( $meta, shift @mapping, shift @mapping );
}

note '';
done_testing;

#===================================
sub test_mapping {
#===================================
    my ( $meta, $name, $test ) = @_;
    $name .= '_attr';
    ok my $attr = $meta->find_attribute_by_name($name), "Has attr: $name";
    return unless $attr;

    if ( ref($test) eq 'HASH' ) {
        is_deeply eval { +{ $tm->find_mapper($attr) } } || $@, $test,
            "Mapping:  $name";
    }
    else {
        throws_ok sub { $tm->find_mapper($attr) }, $test, "$name fails ok";
    }
}

1;
