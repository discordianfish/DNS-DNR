use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DNS::DNR',
    license             => 'perl',
    dist_author         => 'Johannes \'fish\' Ziemke <cpan at the domain called freigeist which belongs to the TLD org>',
    dist_version_from   => 'lib/DNS/DNR.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'DNS-DNR-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
