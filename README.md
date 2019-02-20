[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/rsync.svg)](https://forge.puppetlabs.com/simp/rsync)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/rsync.svg)](https://forge.puppetlabs.com/simp/rsync)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-rsync.svg)](https://travis-ci.org/simp/pupmod-simp-rsync)

## This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our [JIRA](https://simp-project.atlassian.net/).

Please read our [Contribution Guide](http://simp-doc.readthedocs.io/en/stable/contributors_guide/index.html).

## Work in Progress

Please excuse us as we transition this code into the public domain.

Downloads, discussion, and patches are still welcome!

### Configuring Host as Server and Client

By default, in the 'simp' configuration scenario, an rsync server is configured
on the primary Puppet server. In some configurations, it may be necessary to have
supplemental rsync servers to sync files to clients (one example: PE MoM and
Compile Master architecture).

To configure a Compile Master (or other node) to function as both a server
and a client (of the primary server), setup hiera for the node:

```
rsync::server::global::port: 8873
rsync::server::trusted_nets:
  - <client_net>
  - <client_net>
```

This will configure an rsync server that utilizes stunnel for connections
from the client_nets listed. To configure clients to utilize this new server,
set their hieradata:

```
simp_options::rsync: 'fqdn.rsync.server'
```

to override the standard 'true' boolean value.

NOTE: If not using stunnel for the server/client connections, both values for
`rsync::server::trusted_nets` and `rsync::server::global::trusted_nets` will
need to match, as well as the `trusted_nets` values for any `rsync::server::section`
resources. These all default to '127.0.0.1' for stunnel usage.
