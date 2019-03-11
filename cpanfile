requires 'Moose';
requires 'Path::Tiny';
requires 'Throwable::Error';
requires 'Ref::Util';
requires 'YAML::PP';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};
