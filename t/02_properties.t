#!/usr/bin/env perl

use Test::More;
use DeploymentManager;

my $jinja = DeploymentManager::Template::Jinja->new(
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

{
  my $d = DeploymentManager->new(file => 't/examples/import-jinja/deploy.yaml');
  isa_ok($d->document, 'DeploymentManager::Config');
  is_deeply($d->properties, [ ]);
  is_deeply($d->document->properties, [ ]);

  #TODO:
  # isa_ok($d->document->imports->[0], 'DeploymentManager::Template::Jinja');
}

done_testing;
