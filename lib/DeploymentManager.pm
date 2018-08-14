package DeploymentManager::Import;
  use Moose;

  has path => (is => 'ro', isa => 'Str', required => 1);

  sub as_hashref {
    my $self = shift;
    { path => $self->path }
  }

package DeploymentManager::Output;
  use Moose;

  has name => (is => 'ro', isa => 'Str', required => 1);
  has value => (is => 'ro', isa => 'Str', required => 1);

  sub as_hashref {
    my $self = shift;
    { name => $self->name, value => $self->value }
  }

package DeploymentManager::Property;
  use Moose;
  use Moose::Util::TypeConstraints qw/enum/;

  enum 'DeploymentManager::Property::Type', [qw/string boolean integer number/];

  has type => (is => 'ro', isa => 'DeploymentManager::Property::Type', required => 1);
  has default => (is => 'ro');
  has minimum => (is => 'ro');
  has maximum => (is => 'ro');
  has pattern => (is => 'ro');
  #has not X / allOf X, Y / anyOf X, Y / oneOf X, Y

  sub as_hashref {
    my ($self, @ctx) = @_;
    return {
      type => $self->type,
      (defined $self->default) ? (default => $self->default) : (),
      (defined $self->minimum) ? (minimum => $self->minimum) : (),
      (defined $self->maximum) ? (maximim => $self->maximum) : (),
      (defined $self->pattern) ? (pattern => $self->pattern) : (),
    }
  }

package DeploymentManager::Resource::Metadata;
  use Moose;
  use Moose::Util::TypeConstraints;

  coerce 'DeploymentManager::Resource::Metadata' => from 'HashRef' 
    => via { DeploymentManager::Resource::Metadata->new(%$_) };

  has dependsOn => (is => 'ro', isa => 'ArrayRef[Str]');

  sub as_hashref {
    my $self = shift;
    return {
      dependsOn => $self->dependsOn,
    }
  }

package DeploymentManager::Resource;
  use Moose;

  has name => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);
  #TODO: don't know if properties is really required
  has properties => (is => 'ro', isa => 'HashRef', required => 1); 
  has metadata => (is => 'ro', isa => 'DeploymentManager::Resource::Metadata', coerce => 1);

  sub as_hashref {
    my ($self, @ctx) = @_;
    return {
      name => $self->name,
      type => $self->type,
      properties => $self->properties,
      (defined $self->metadata) ? (metadata => $self->metadata->as_hashref(@ctx)) : (),
    };
  }

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

  has outputs => (
    is => 'ro',
    isa => 'ArrayRef[DeploymentManager::Output]',
    traits => [ 'Array' ],
    handles => { num_of_outputs => 'count' },
  );

  has resources => (
    is => 'ro',
    isa => 'ArrayRef[DeploymentManager::Resource]',
    lazy => 1,
    builder => 'build_resources',
    traits => [ 'Array' ],
    handles => {
      num_of_resources => 'count'
    },
  );

  sub build_content {
    my $self = shift;
    return path($self->file)->slurp;
  }

  sub as_hashref {
    my ($self, @ctx) = @_;
    return {
      resources => [ map { $_->as_hashref(@ctx) } @{ $self->resources } ],
      (defined $self->outputs) ? (outputs => [ map { $_->as_hashref(@ctx) } @{ $self->outputs } ]) : (),
    };
  }

package DeploymentManager::Template;
  use Moose;
  extends 'DeploymentManager::Document';
  use YAML::PP;

  has property_values => (is => 'ro', isa => 'HashRef');
  has environment => (is => 'ro', isa => 'HashRef');
  has processed_template => (is => 'ro', isa => 'Str', lazy => 1, builder => 'process_template');
  has processed_yaml => (is => 'ro', isa => 'HashRef', lazy => 1, builder => 'build_processed_yaml');

  sub process_template {
    my $self = shift;
    if (not defined $self->property_values or not defined $self->environment) {
      die "Can't process a template without having property_values and environment attributes set"
    }
    #TODO: process the Jinja template
    die "Can't process Jinja template yet";
  }

  sub build_processed_yaml {
    my $self = shift;
    YAML::PP->new->load_string($self->processed_template);
  }

  sub build_resources {
    my $self = shift;
    return [ 
      map { DeploymentManager::Resource->new(%$_) } @{ $self->processed_yaml->{ resources } }
    ];
  }

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

  has imports => (
    is => 'ro',
    isa => 'ArrayRef[DeploymentManager::Import]',
  );

  # A config doesn't have externally facing properties. It defines all properties
  # used in it's imports directly (you can't specify properties when creating a
  # --config ....yaml deployment
  sub build_properties { [ ] }

  sub build_resources { [ ] }

  around as_hashref => sub {
    my ($orig, $self, @ctx) = @_;

    my $hr = $self->$orig(@ctx);
    if (defined $self->imports) {
      $hr->{ imports } = [ map { $_->as_hashref(@ctx) } @{ $self->imports } ];
    }
    return $hr;
  };

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
