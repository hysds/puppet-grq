# GRQ

Puppet module to install all software needed to run
a GeoRegionQuery(GRQ) server and data product catalog.

## Prerequisites

Create a base CentOS7 image as described [here](https://github.com/hysds/hysds-framework/wiki/Puppet-Automation#create-a-base-centos-7-image-for-installation-of-all-hysds-component-instances).

## Installation

As _root_ run:

```sh
bash < <(curl -skL https://github.com/earthobservatory/puppet-grq/raw/azure-beta1/install.sh)
```
