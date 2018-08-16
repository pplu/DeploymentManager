#!/usr/bin/env perl

use DeploymentManager;
use Test::More;

{
  my $d = DeploymentManager::File->new(
    file => 't/examples/simple/deploy.yaml'
  );

  cmp_ok($d->file, 'eq', 't/examples/simple/deploy.yaml');
  cmp_ok($d->type, 'eq', 'config');
}

{
  my $d = DeploymentManager::File->new(
    file => 't/examples/simple/deploy.jinja'
  );

  cmp_ok($d->file, 'eq', 't/examples/simple/deploy.jinja');
  cmp_ok($d->type, 'eq', 'template_jinja');
}

{
  my $d = DeploymentManager::File->new(
    file => 't/examples/simple/deploy.py'
  );

  cmp_ok($d->file, 'eq', 't/examples/simple/deploy.py');
  cmp_ok($d->type, 'eq', 'template_python');
}

done_testing;
