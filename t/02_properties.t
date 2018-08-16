#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use DeploymentManager;

{
  my $jinja = DeploymentManager::Template::Jinja::Unprocessed->new(
    file => 't/examples/properties/propertes.jinja',
  );

  is_deeply($jinja->properties, [ 
    'additionalPermission',
    'description',
    'filter',
    'isOrgnizationRole',
    'orgnizationId',
    'roleId'
  ]);
  cmp_ok($jinja->num_of_properties, '==', 6);
}

{
  my $d = DeploymentManager::File->new(file => 't/examples/import-jinja/deploy.yaml');
  isa_ok($d->document, 'DeploymentManager::Config::Unprocessed');
  cmp_ok($d->num_of_properties, '==', 0);
  is_deeply($d->properties, [ ]);

  my $p = $d->document->process;
  isa_ok($p, 'DeploymentManager::Config');
  isa_ok($p->imports->[0], 'DeploymentManager::Import');
  cmp_ok($p->num_of_resources, '==', 1);
}

done_testing;
