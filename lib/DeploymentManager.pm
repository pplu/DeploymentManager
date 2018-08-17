package DeploymentManager::Import;
  use Moose;

  has path => (is => 'ro', isa => 'Str', required => 1);

  sub from_hashref {
    my ($self, $hr) = @_;
    my $init_args = {};
    $init_args->{ path } = $hr->{ path } if (defined $hr->{ path });
    DeploymentManager::Import->new($init_args);
  }

  sub as_hashref {
    my $self = shift;
    { path => $self->path }
  }

package DeploymentManager::Output;
  use Moose;

  has name => (is => 'ro', isa => 'Str', required => 1);
  has value => (is => 'ro', isa => 'Str', required => 1);

  sub from_hashref {
    my ($self, $hr) = @_;
    my $init_args = {};
    $init_args->{ name } = $hr->{ name } if (defined $hr->{ name });
    $init_args->{ value } = $hr->{ value } if (defined $hr->{ value });
    DeploymentManager::Output->new($init_args);
  }

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

  has dependsOn => (is => 'ro', isa => 'ArrayRef[Str]');

  sub from_hashref {
    my ($class, $hr) = @_;
    my $init_args = {};
    $init_args->{ dependsOn } = $hr->{ dependsOn } if (defined $hr->{ dependsOn });
    DeploymentManager::Resource::Metadata->new(%$init_args);
  }

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
  has metadata => (is => 'ro', isa => 'DeploymentManager::Resource::Metadata');

  sub from_hashref {
    my ($self, $hr) = @_;
    my $init_args = {};
    $init_args->{ name } = $hr->{ name } if (defined $hr->{ name });
    $init_args->{ type } = $hr->{ type } if (defined $hr->{ type });
    $init_args->{ properties } = $hr->{ properties };
    $init_args->{ metadata } = DeploymentManager::Resource::Metadata->from_hashref($hr->{ metadata }) if (defined $hr->{ metadata });
    DeploymentManager::Resource->new($init_args);
  }

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

  has outputs => (
    is => 'ro',
    isa => 'ArrayRef[DeploymentManager::Output]',
  );

  has resources => (
    is => 'ro',
    isa => 'ArrayRef[DeploymentManager::Resource]',
  );

  sub num_of_outputs {
    my $self = shift;
    return 0 if (not defined $self->outputs);
    return scalar(@{ $self->outputs });
  }

  sub num_of_resources {
    my $self = shift;
    return 0 if (not defined $self->resources);
    return scalar(@{ $self->resources });
  }

  sub as_hashref {
    my ($self, @ctx) = @_;
    return {
      (defined $self->resources) ? (resources => [ map { $_->as_hashref(@ctx) } @{ $self->resources } ] ) : (),
      (defined $self->outputs) ? (outputs => [ map { $_->as_hashref(@ctx) } @{ $self->outputs } ]) : ()
    };
  }

package DeploymentManager::Template;
  use Moose;
  extends 'DeploymentManager::Document';

  has properties => (
    is => 'ro',
    isa => 'ArrayRef',
    traits => [ 'Array' ],
    handles => { num_of_properties => 'count' },
  );

package DeploymentManager::Document::Unprocessed;
  use Moose;
  extends 'DeploymentManager::File';

  has properties => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    builder => 'build_properties',
    traits => [ 'Array' ],
    handles => { num_of_properties => 'count' },
  );

  sub process {
    die "Unimplemented";
  };

package DeploymentManager::Config::Unprocessed;
  use Moose;
  extends 'DeploymentManager::Document::Unprocessed';
  use YAML::PP;

  sub process {
    my ($self, $context) = @_;
    #TODO: produce a DeploymentManager::Config with self->content
    my $struct = YAML::PP->new->load_string($self->content);
    return DeploymentManager::Config->from_hashref($struct);
  }

  # A config doesn't have externally facing properties. It defines all properties
  # used in it's imports directly (you can't specify properties when creating a
  # --config ....yaml deployment
  sub build_properties { [ ] }

package DeploymentManager::Template::Jinja::Unprocessed;
  use Moose;
  extends 'DeploymentManager::Document::Unprocessed';
  use YAML::PP;

  sub process {
    my ($self, $context) = @_;
    #TODO: produce a DeploymentManager::Template::Jinja with self->content
    my $struct = YAML::PP->new->load_string($self->content);
    return DeploymentManager::Template::Jinja->from_hashref($struct);
  }

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

package DeploymentManager::Template::Jinja;
  use Moose;
  extends 'DeploymentManager::Template';

  sub from_hashref {
    my ($self, $hr) = @_;
    my $init_args = {};
    if (defined $hr->{ resources }) {
      $init_args->{ resources } = [ map { DeploymentManager::Resource->from_hashref($_) } @{ $hr->{ resources } } ];
    }
    if (defined $hr->{ outputs }) {
      $init_args->{ outputs } = [ map { DeploymentManager::Output->from_hashref($_) } @{ $hr->{ outputs } } ];
    }
    DeploymentManager::Template::Jinja->new($init_args);
  }

package DeploymentManager::Config;
  use Moose;
  extends 'DeploymentManager::Document';

  has imports => (
    is => 'ro',
    isa => 'ArrayRef[DeploymentManager::Import]',
  );

  sub num_of_imports {
    my $self = shift;
    return 0 if (not defined $self->imports);
    return scalar(@{ $self->imports });
  }

  sub from_hashref {
    my ($self, $hr) = @_;
    my $init_args = {};
    if (defined $hr->{ resources }) {
      $init_args->{ resources } = [ map { DeploymentManager::Resource->from_hashref($_) } @{ $hr->{ resources } } ];
    }
    if (defined $hr->{ outputs }) {
      $init_args->{ outputs } = [ map { DeploymentManager::Output->from_hashref($_) } @{ $hr->{ outputs } } ];
    }
    if (defined $hr->{ imports }) {
      $init_args->{ imports } = [ map { DeploymentManager::Import->from_hashref($_) } @{ $hr->{ imports } } ];
    }
    DeploymentManager::Config->new($init_args);
  }

  around as_hashref => sub {
    my ($orig, $self, @ctx) = @_;

    my $hr = $self->$orig(@ctx);
    if (defined $self->imports) {
      $hr->{ imports } = [ map { $_->as_hashref(@ctx) } @{ $self->imports } ];
    }
    return $hr;
  };

package DeploymentManager::File;
  use Moose;
  use Path::Tiny;

  has file => (is => 'ro', isa => 'Str');
  has content => (is => 'ro', isa => 'Str', required => 1, lazy => 1, builder => 'build_content');

  has type => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;
    return 'template_jinja'  if ($self->file =~ m/\.jinja$/);
    return 'template_python' if ($self->file =~ m/\.py$/);
    return 'config'          if ($self->file =~ m/\.yaml$/);
    die "Unrecognized file type";
  });

  has document => (
    is => 'ro',
    isa => 'DeploymentManager::Document::Unprocessed',
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
      DeploymentManager::Config::Unprocessed->new(file => $self->file);
    } elsif ($self->type eq 'template_jinja') {
      DeploymentManager::Template::Jinja::Unprocessed->new(file => $self->file);
    } else {
      die "Unsupported document type";
    }
  }

  sub build_content {
    my $self = shift;
    die "Can't load content if file isn't defined" if (not defined $self->file);
    return path($self->file)->slurp;
  }

package DeploymentManager;
  use Moose;

  our $VERSION = '0.01';

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
