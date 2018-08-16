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
      } ]
    }
  );
}


done_testing;
