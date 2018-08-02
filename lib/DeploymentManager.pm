package DeploymentManager;
  use Moose;

  has file => (is => 'ro', isa => 'Str', required => 1);

1;
