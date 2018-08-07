#!/usr/bin/env perl

use strict;
use warnings;
use DeploymentManager;
use Test::More;

{ 
  # With metadata
  my $r = DeploymentManager::Resource->new(
    name => 'n1',
    type => 't1',
    properties => {
      prop1 => 'prop1value',
    },
    metadata => DeploymentManager::Resource::Metadata->new(
      dependsOn => [ 'r2' ]
    ),
  );

  is_deeply(
    $r->as_hashref,
    {
      name => 'n1',
      type => 't1',
      properties => { prop1 => 'prop1value' },
      metadata => { dependsOn => [ 'r2' ] },
    }
  );
}

{
  # No metadata
  my $r = DeploymentManager::Resource->new(
    name => 'n1',
    type => 't2',
    properties => {
      prop2 => 'prop2value',
    },
  );

  is_deeply(
    $r->as_hashref,
    {
      name => 'n1',
      type => 't2',
      properties => { prop2 => 'prop2value' },
    }
  );
}

done_testing;
