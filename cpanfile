requires 'Moose';
requires 'Path::Tiny';
requires 'Throwable::Error';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::Exception';
};
