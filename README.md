# mediawiki

#### Table of Contents

1. [Overview](#overview)
1. [Setup - The basics of getting started with mediawiki](#setup)
    * [What mediawiki affects](#what-mediawiki-affects)
    * [Dependencies](#dependencies)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Overview

Multi-instance MediaWiki installation

## Setup

### What mediawiki affects

* Installation of mediawiki
* Configuration of multiple mediawiki instances
* Apache VirtualHosts associated with each wiki instance

### Dependencies

swh-mediawiki depends on the puppetlabs-apache module, as well as
puppetlabs-stdlib.

## Usage

### mediawiki class

The mediawiki class handles the installation of mediawiki as well as the
management of the several mediawiki instances.

### mediawiki_instance resource

The mediawiki_instance resource allows the definition of several mediawiki
instances on one host.

## Limitations

This has only been tested on Debian.

## Development

This module is internal to Software Heritage but published in the hope that it
will be useful.
