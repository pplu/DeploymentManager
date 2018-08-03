package DeploymentManager::Document;
  use Moose;
  use Path::Tiny;

  has file => (is => 'ro', isa => 'Str');
  has content => (is => 'ro', isa => 'Str', required => 1, lazy => 1, builder => 'build_content');

  has properties => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    builder => 'build_properties',
    traits => [ 'Array' ],
    handles => { num_of_properties => 'count' },
  );

  sub build_content {
    my $self = shift;
    return path($self->file)->slurp;
  }

package DeploymentManager::Template;
  use Moose;
  extends 'DeploymentManager::Document';

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
  sub build_properties { [ ] }

package DeploymentManager;
  use Moose;

  our $VERSION = '0.01';

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
      num_of_properties => 'num_of_properties',
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
### main pod documentation begin ###
 
=encoding UTF-8
 
=head1 NAME
 
DeploymentManager - An object model for Google DeploymentManager templates
 
=head1 SYNOPSIS
 
  use DeploymentManager;
 
  my $dm = DeploymentManager->new(
    file => '...',
  );
 
=head1 DESCRIPTION
 
This module creates an object model of Google DeploymentManager templates
 
=head1 ATTRIBUTES
 
=head2 file

The file that contains

=head2 document

A property that contains the object for the file. It will contain a subclass
of L<DeploymentManager::Document>.

This can be a L<DeploymentManager::Template::Jinja> or a L<DeploymentManager::Template::Python>
 
=head2 properties

An Array with the properties in the document

=head2 num_of_properties

The number of properties declared in the document
 
=head1 SEE ALSO
 
L<https://cloud.google.com/deployment-manager/docs/>
 
=head1 AUTHOR
 
    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com
 
=head1 BUGS and SOURCE
 
The source code is located here: L<https://github.com/pplu/DeploymentManager.git>
 
Please report bugs to: L<https://github.com/pplu/DeploymentManager/issues>
 
=head1 COPYRIGHT and LICENSE
 
Copyright (c) 2018 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.
 
=cut
