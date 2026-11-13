[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/rsync.svg)](https://forge.puppetlabs.com/simp/rsync)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/rsync.svg)](https://forge.puppetlabs.com/simp/rsync)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-rsync.svg)](https://travis-ci.org/simp/pupmod-simp-rsync)

## This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our [JIRA](https://simp-project.atlassian.net/).

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

## Module Description

This module configures rsync for sharing large files that would be problematic to
share using the native Puppet fileserving type.

## Setup

### Configuring Host as Server and Client

By default, in the 'simp' configuration scenario, an rsync server is configured
on the primary Puppet server. In some configurations, it may be necessary to have
supplemental rsync servers to sync files to clients (one example: PE MoM and
Compile Master architecture).

To configure a Compile Master (or other node) to function as both a server
and a client (of the primary server), set hieradata for the node as shown
below for your connection type.

#### With stunnel (the default)

On the node that will serve files, set:

```yaml
rsync::server::global::port: 8873
rsync::server::trusted_nets:
  - <client_net>
  - <client_net>
```

The node is still a client of the primary server, and its own rsync stunnel
connection already listens on `127.0.0.1:873`, so the local rsync daemon
moves to port 8873. Clients in the listed `client_net`s reach it through
stunnel on port 8730.

To configure clients to use this new server instead of the primary Puppet
server, set their hieradata:

```yaml
simp::rsync_stunnel: 'fqdn.rsync.server'
```

`simp::rsync_stunnel` defaults to `true`, which points the client's rsync
stunnel connection at the primary Puppet server. Nodes that do not include
the `simp` class must declare the equivalent `stunnel::connection` themselves.

#### Without stunnel

The rsync daemon must listen on an external address, and the values of
`rsync::server::trusted_nets`, `rsync::server::global::trusted_nets` and the
`trusted_nets` of any `rsync::server::section` resources must match:

```yaml
rsync::server::stunnel: false
rsync::server::global::address: '0.0.0.0'
rsync::server::trusted_nets:
  - <client_net>
rsync::server::global::trusted_nets:
  - <client_net>
```

Clients then connect to the server directly:

```yaml
simp_options::rsync::server: 'fqdn.rsync.server'
```

## Reference

Please refer to the [REFERENCE.md](./REFERENCE.md).

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise
Linux and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

Visit the project homepage on [GitHub](https://simp-project.com),
and look at our issues on  [JIRA](https://simp-project.atlassian.net/).
