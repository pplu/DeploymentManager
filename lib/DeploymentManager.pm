package DeploymentManager::Document;
  use Moose;
  use Path::Tiny;

  has file => (is => 'ro', isa => 'Str');
  has content => (is => 'ro', isa => 'Str', required => 1, lazy => 1, builder => 'build_content');

  sub build_content {
    my $self = shift;
    return path($self->file)->slurp;
  }

package DeploymentManager::Template;
  use Moose;
  extends 'DeploymentManager::Document';

  has properties => (is => 'ro', isa => 'ArrayRef', lazy => 1, builder => 'build_properties');

package DeploymentManager::Template::Jinja;
  use Moose;
  extends 'DeploymentManager::Template';

  sub build_properties {
    my $self = shift;
   
    my %props = ();
    my $content = $self->content;
    # find {{ properties["..."] }} (double quotes) interpolations
    while ($content =~ m/\{\{\s*properties\[\"(.*?)\"\]\s*\}\}/g) {
      my $property = $1;
      $props{ $property } = 1;
    }
    # find {{ properties['...'] }} (single quote) interpolations
    while ($content =~ m/\{\{\s*properties\[\'(.*?)\'\]\s*\}\}/g) {
      my $property = $1;
      $props{ $property } = 1;
    }
    # find references to double quoted properties within expressions
    while ($content =~ m/\{\%.*?properties\[\"(.*?)\"\].*?\%\}/g) {
      my $property = $1;
      $props{ $property } = 1;
    }
    # find references to single quotes properties within expressions
    while ($content =~ m/\{\%.*?properties\[\'(.*?)\'\].*?\%\}/g) {
      my $property = $1;
      $props{ $property } = 1;
    }

    return [ sort keys %props ];
  }

package DeploymentManager::Config;
  use Moose;
  extends 'DeploymentManager::Document';

  # A config doesn't have externally facing properties. It defines all properties
  # used in it's imports directly (you can't specify properties when creating a
  # --config ....yaml deployment
  has properties => (is => 'ro', isa => 'ArrayRef', default => sub { [ ] });

package DeploymentManager;
  use Moose;

  has file => (is => 'ro', isa => 'Str', required => 1);

  has type => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;
    return 'template_jinja'  if ($self->file =~ m/\.jinja$/);
    return 'template_python' if ($self->file =~ m/\.py$/);
    return 'config'          if ($self->file =~ m/\.yaml$/);
    die "Unrecognized file type";
  });

  has document => (
    is => 'ro',
    isa => 'DeploymentManager::Document',
    lazy => 1,
    builder => 'build_document',
    handles => {
      properties => 'properties',
    },
  );

  sub build_document {
    my ($self, $file) = @_;

    if      ($self->type eq 'config') {
      DeploymentManager::Config->new(file => $self->file);
    } elsif ($self->type eq 'template_jinja') {
      DeploymentManager::Template::Jinja->new(file => $self->file);
    } else {
      die "Unsupported document type";
    }
  }

1;
