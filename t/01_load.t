#!/usr/bin/env perl

use DeploymentManager;
use Test::More;

my $d = DeploymentManager->new(
  file => 't/examples/simple/deploy.yaml'
);

cmp_ok($d->file, 'eq', 't/examples/simple/deploy.yaml');

done_testing;
