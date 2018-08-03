# NAME

DeploymentManager - An object model for Google DeploymentManager templates

# SYNOPSIS

     use DeploymentManager;
    
     my $dm = DeploymentManager->new(
       file => '...',
     );
    

# DESCRIPTION

This module creates an object model of Google DeploymentManager templates

# ATTRIBUTES

## file

The file that contains

## document

A property that contains the object for the file. It will contain a subclass
of [DeploymentManager::Document](https://metacpan.org/pod/DeploymentManager::Document).

This can be a [DeploymentManager::Template::Jinja](https://metacpan.org/pod/DeploymentManager::Template::Jinja) or a [DeploymentManager::Template::Python](https://metacpan.org/pod/DeploymentManager::Template::Python)

## properties

An Array with the properties in the document

## num\_of\_properties

The number of properties declared in the document

# SEE ALSO

[https://cloud.google.com/deployment-manager/docs/](https://cloud.google.com/deployment-manager/docs/)

# AUTHOR

       Jose Luis Martinez
       CAPSiDE
       jlmartinez@capside.com
    

# BUGS and SOURCE

The source code is located here: [https://github.com/pplu/DeploymentManager.git](https://github.com/pplu/DeploymentManager.git)

Please report bugs to: [https://github.com/pplu/DeploymentManager/issues](https://github.com/pplu/DeploymentManager/issues)

# COPYRIGHT and LICENSE

Copyright (c) 2018 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.
