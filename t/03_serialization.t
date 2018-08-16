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

  my $r1_hash = {
    name => 'n1',
    type => 't1',
    properties => { prop1 => 'prop1value' },
    metadata => { dependsOn => [ 'r2' ] },
  };
  is_deeply(
    $r->as_hashref,
    $r1_hash,
  );

  my $d = DeploymentManager::Template::Jinja->new(
    resources => [ $r ],
  );

  is_deeply(
    $d->as_hashref,
    { resources => [ $r1_hash ] }
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

  my $r1_hash = {
    name => 'n1',
    type => 't2',
    properties => { prop2 => 'prop2value' },
  };

  is_deeply(
    $r->as_hashref,
    $r1_hash,
  );

  my $d = DeploymentManager::Template::Jinja->new(
    outputs => [ DeploymentManager::Output->new(name => 'o1', value => 'v1') ],
    resources => [ $r ],
  );

  is_deeply(
    $d->as_hashref,
    { resources => [ $r1_hash ],
      outputs => [ { name => 'o1', value => 'v1' } ] 
    }
  );
}

{
  my $d = DeploymentManager::Config->new(
    outputs => [ DeploymentManager::Output->new(name => 'o1', value => 'v1') ],
    imports => [ DeploymentManager::Import->new(path => 'path1') ],
  );

  is_deeply(
    $d->as_hashref,
    { outputs => [ { name => 'o1', value => 'v1' } ],
      imports => [ { path => 'path1' } ]
    }
  );
}


done_testing;
