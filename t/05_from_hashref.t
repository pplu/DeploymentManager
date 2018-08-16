#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use DeploymentManager;

{
  my $hr = {
    imports => [ { path => 'path_value' } ],
    resources => [ {
      name => 'deployment',
      type => 'type',
      properties => { p1 => 'v1' },
    } ],
    outputs => [
      { name => 'o1', value => 'v1' },
      { name => 'o2', value => 'v2' },
    ],
  };

  my $c = DeploymentManager::Config->from_hashref($hr);
  is_deeply(
    $c->as_hashref,
    $hr
  );
}

{
  my $hr = {
    resources => [ {
      name => 'deployment',
      type => 'type',
      properties => { p1 => 'v1' },
    } ],
    outputs => [
      { name => 'o1', value => 'v1' },
      { name => 'o2', value => 'v2' },
    ],
  };

  my $c = DeploymentManager::Template::Jinja->from_hashref($hr);
  is_deeply(
    $c->as_hashref,
    $hr
  );
}


done_testing;
