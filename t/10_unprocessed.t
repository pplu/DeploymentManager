#!/usr/bin/env perl

use strict;
use warnings;
use DeploymentManager;
use Test::More;

{ 
  my $d = DeploymentManager::Template::Jinja::Unprocessed->new(
    content => <<EOT,
resources:
 - name: r1
   type: t1
   properties:
     prop1: prop1value
EOT
  );

  my $p = $d->process;
  cmp_ok($p->num_of_resources, '==', 1);
  cmp_ok($p->num_of_outputs, '==', 0);
  is_deeply(
    $p->as_hashref,
    { resources => [ {
        name => 'r1',
        type => 't1',
        properties => {
          prop1 => 'prop1value',
        },
      } ]
    }
  );
}

{ 
  my $d = DeploymentManager::Template::Jinja::Unprocessed->new(
    content => <<EOT,
resources:
 - name: r1
   type: t1
   properties:
     prop1: prop1value
   metadata:
     dependsOn: [ r1 ]
outputs:
 - name: o1
   value: v1
EOT
  );

  my $p = $d->process;
  cmp_ok($p->num_of_resources, '==', 1);
  is_deeply(
    $p->as_hashref,
    { resources => [ {
        name => 'r1',
        type => 't1',
        properties => {
          prop1 => 'prop1value',
        },
        metadata => {
          dependsOn => [ 'r1' ],
        }
      } ],
      outputs => [ { name => 'o1', value => 'v1' } ],
    }
  );
}

{ 
  my $d = DeploymentManager::Template::Jinja::Unprocessed->new(
    content => '',
  );

  my $p = $d->process;
  cmp_ok($p->num_of_resources, '==', 0);
  cmp_ok($p->num_of_outputs, '==', 0);
  is_deeply(
    $p->as_hashref,
    { }
  );
}

{ 
  my $d = DeploymentManager::Config::Unprocessed->new(
    content => <<EOT,
imports:
 - path: path/to/import1
resources:
 - name: r1
   type: t1
   properties:
     prop1: prop1value
outputs:
 - name: o1
   value: v1
EOT
  );

  my $p = $d->process;
  cmp_ok($p->num_of_resources, '==', 1);
  cmp_ok($p->num_of_imports, '==', 1);
  cmp_ok($p->num_of_outputs, '==', 1);
  is_deeply(
    $p->as_hashref,
    { outputs => [ { name => 'o1', value => 'v1' } ],
      imports => [ { path => 'path/to/import1' } ],
      resources => [ {
        name => 'r1',
        type => 't1',
        properties => {
          prop1 => 'prop1value',
        },
      } ]
    }
  );
}

{ 
  my $d = DeploymentManager::Config::Unprocessed->new(
    content => <<EOT,
imports:
resources:
outputs:
EOT
  );

  my $p = $d->process;
  cmp_ok($p->num_of_resources, '==', 0);
  cmp_ok($p->num_of_imports, '==', 0);
  cmp_ok($p->num_of_outputs, '==', 0);
  is_deeply(
    $p->as_hashref,
    { }
  );
}




done_testing;
