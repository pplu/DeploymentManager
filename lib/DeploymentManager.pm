package DeploymentManager::ParseError;
  use Moose;
  extends 'Throwable::Error';

  has path => (is => 'ro', isa => 'Str', required => 1);

  sub as_string {
    my $self = shift;
    'Parse Error in path: "' . $self->path . '": ' . $self->message;
  }

package DeploymentManager::CoerceToAndFromHashRefs;
  use Moose::Role;
  use Ref::Util qw/is_ref is_hashref/;

  sub _make_path { 
    shift @_ if ($_[0] eq '');
    join '.', @_ 
  }

  sub from_hashref {
    my ($class, $hr, $path) = @_;

    $path = '' if (not defined $path);

    DeploymentManager::ParseError->throw(
      message => 'expecting a hashref',
      path => $path,
    ) if (not is_hashref($hr));

    # since we'll be deleting keys from $hr, we don't want them disappearing from the
    # original hashref
    $hr = { %$hr };
    my $init_args = {};

    # Take care of "coercions" to the type of the attribute. Don't try to verify
    # types, since that will be done by Moose while constructing the object.
    # Prepare $hr to detect if there are extra, unknown attributes by deleting the keys.
    foreach my $att ($class->meta->get_all_attributes) {
      my $attribute = $att->name;
      next if (not exists $hr->{ $attribute });
      my $value = delete $hr->{ $attribute };

      if ($att->type_constraint->isa('Moose::Meta::TypeConstraint::Class')){
        my $res = eval {
          $init_args->{ $attribute } = 
            $att->type_constraint->name->from_hashref($value, _make_path($path,$attribute));
        };
        if ($@) {
          if (ref($@) and $@->isa('DeploymentManager::ParseError') and $@->message eq 'expecting a hashref') {
            DeploymentManager::ParseError->throw(
              message => $attribute . ' is of invalid type',
              path => _make_path($path, $attribute),
            );
          } else {
            die $@;
          }
        }
      } elsif ($att->type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized')){
        if ($att->type_constraint->parameterized_from eq 'ArrayRef') {
          my $constraint = $att->type_constraint;

          if ($constraint->type_parameter->isa('Moose::Meta::TypeConstraint::Class')){
            my $i = 0;
            $init_args->{ $attribute } = [
              map {
                $constraint->type_parameter->name->from_hashref($_, _make_path($path, $attribute, $i++))
              } @$value
            ];
          } else {
            $init_args->{ $attribute } = $value;
          }
        } elsif ($att->type_constraint->parameterized_from eq 'HashRef') {
          die "Can't handle HashRef of things";
        } else {
          die "Unknown parameterized type";
        }
      } else {
        $init_args->{ $attribute } = $value;
      }
    }

    # Detect if in $hr there were extra keys that don't correspond to attributes 
    if (keys %$hr) {
      my $example_key = (keys %$hr)[0];
      DeploymentManager::ParseError->throw(
        message => $example_key . ' is not a valid attribute',
        path => _make_path($path, $example_key),
      );
    }

    # Let Moose do all the hard work of detecting if an attribute is required, of the
    # correct type, etc.
    my $return = eval {
      $class->new($init_args);
    };
    if ($@) {
      #use Data::Dumper;
      #print Dumper($@);

      if ($@->isa('Moose::Exception::AttributeIsRequired')){
        DeploymentManager::ParseError->throw(
          message => $@->attribute_name . ' is required',
          path => _make_path($path, $@->attribute_name),
        );
      } elsif ($@->isa('Moose::Exception::ValidationFailedForTypeConstraint')){
         DeploymentManager::ParseError->throw(
          message => $@->attribute->name . ' is of invalid type',
          path => _make_path($path, $@->attribute->name),
        );
      } else {
        die $@;
      }
    } else {
      return $return;
    }
  }

  sub as_hashref {
    my ($self, @ctx) = @_;
    
    my $hashref = {};
    foreach my $att ($self->meta->get_all_attributes) {
      my $attribute = $att->name;
      next if (not defined $self->$attribute);

      if ($att->type_constraint->isa('Moose::Meta::TypeConstraint::Class')){
        $hashref->{ $attribute } = $self->$attribute->to_hashref(@ctx);
      } else {
        $hashref->{ $attribute } = $self->$attribute;
      }
    }
    return $hashref;
  }

package DeploymentManager::Import;
  use Moose;
  with 'DeploymentManager::CoerceToAndFromHashRefs';

  has path => (is => 'ro', isa => 'Str', required => 1);

package DeploymentManager::Output;
  use Moose;
  with 'DeploymentManager::CoerceToAndFromHashRefs';

  has name => (is => 'ro', isa => 'Str', required => 1);
  has value => (is => 'ro', isa => 'Str', required => 1);

package DeploymentManager::Property;
  use Moose;
  use Moose::Util::TypeConstraints qw/enum/;
  with 'DeploymentManager::CoerceToAndFromHashRefs';

  enum 'DeploymentManager::Property::Type', [qw/string boolean integer number/];

  has type => (is => 'ro', isa => 'DeploymentManager::Property::Type', required => 1);
  has default => (is => 'ro');
  has minimum => (is => 'ro');
  has maximum => (is => 'ro');
  has pattern => (is => 'ro');
  #has not X / allOf X, Y / anyOf X, Y / oneOf X, Y

package DeploymentManager::Resource::Metadata;
  use Moose;
  with 'DeploymentManager::CoerceToAndFromHashRefs';

  has dependsOn => (is => 'ro', isa => 'ArrayRef[Str]');

  #TODO: this method is not being inherited from the CoerceToAndFromHashRefs role, and I don't
  #      know why :S
  sub to_hashref { { dependsOn => shift->dependsOn } };

package DeploymentManager::Resource;
  use Moose;
  with 'DeploymentManager::CoerceToAndFromHashRefs';

  has name => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);
  #TODO: don't know if properties is really required
  has properties => (is => 'ro', isa => 'HashRef', required => 1); 
  has metadata => (is => 'ro', isa => 'DeploymentManager::Resource::Metadata');

package DeploymentManager::Document;
  use Moose;
  with 'DeploymentManager::CoerceToAndFromHashRefs';

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
