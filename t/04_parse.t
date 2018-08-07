#!/usr/bin/env perl

use strict;
use warnings;
use DeploymentManager;
use Test::More;

{ 
  my $d = DeploymentManager::Template::Jinja->new(
    processed_template => <<EOT,
resources:
 - name: r1
   type: t1
   properties:
     prop1: prop1value
EOT
  );

  cmp_ok($d->num_of_resources, '==', 1);
  is_deeply(
    $d->as_hashref,
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
  my $d = DeploymentManager::Template::Jinja->new(
    processed_template => <<EOT,
resources:
 - name: r1
   type: t1
   properties:
     prop1: prop1value
   metadata:
     dependsOn: [ r1 ]
EOT
  );

  cmp_ok($d->num_of_resources, '==', 1);
  is_deeply(
    $d->as_hashref,
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
