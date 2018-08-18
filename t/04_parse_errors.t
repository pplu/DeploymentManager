#!/usr/bin/env perl

use strict;
use warnings;
use DeploymentManager;
use Test::More;
use Test::Exception;

{
  throws_ok(sub { 
    # ups... didn't pass a hashref...
    DeploymentManager::Resource->from_hashref(
      name => {},
      type => 'type1',
      properties => {},
    );
  }, 'DeploymentManager::ParseError');
  like($@->message, qr/^expecting a hashref$/);
  cmp_ok($@->path, 'eq', '');
}

{
  throws_ok(sub { 
    DeploymentManager::Resource::Metadata->from_hashref(5);
  }, 'DeploymentManager::ParseError');
  like($@->message, qr/^expecting a hashref$/);
  cmp_ok($@->path, 'eq', '');
}

{
  throws_ok(sub { 
    DeploymentManager::Resource->from_hashref({
      type => 'type1',
      properties => {},
    });
  }, 'DeploymentManager::ParseError');
  like($@->message, qr/name is required/);
  cmp_ok($@->path, 'eq', 'name');
}

{
  throws_ok(sub { 
    DeploymentManager::Resource->from_hashref({
      name => {},
      type => 'type1',
      properties => {},
    });
  }, 'DeploymentManager::ParseError');
  like($@->message, qr/name is of invalid type/);
  cmp_ok($@->path, 'eq', 'name');
}

{
  throws_ok(sub { 
    DeploymentManager::Resource->from_hashref({
      name => 'name',
      type => 'type1',
      properties => {},
      extra_attribute => 5,
    });
  }, 'DeploymentManager::ParseError');
  like($@->message, qr/extra_attribute is not a valid attribute/);
  cmp_ok($@->path, 'eq', 'extra_attribute');
}

{
  throws_ok(sub { 
    DeploymentManager::Resource::Metadata->from_hashref({
      dependsOn => { }
    });
  }, 'DeploymentManager::ParseError');
  like($@->message, qr/dependsOn is of invalid type/);
  cmp_ok($@->path, 'eq', 'dependsOn');


}

{
  throws_ok(sub { 
    DeploymentManager::Resource->from_hashref({
      name => 'name',
      type => 'type1',
      properties => {},
      metadata => 5,
    });
  }, 'DeploymentManager::ParseError');
  like($@->message, qr/metadata is of invalid type/);
  cmp_ok($@->path, 'eq', 'metadata');
}

done_testing;
