# @summary Sets up a fully functioning rsync server.
#
# The main idea behind this was to work around limitations of the native Puppet
# fileserving type.
#
# Most usual options are supported, but there are far too many to tackle all of
# them at once.
#
# This mainly daemonizes rsync and keeps it running. It will also subscribe it
# to the stunnel service if it has been declared.
#
# @param stunnel
#   Use Stunnel to encrypt this connection. It is *highly* recommended to leave
#   this enabled.
#
# @param stunnel_port
#   The port upon which Stunnel should listen for connections.
#
# @param listen_port
#   The port upon which the rsync daemon should listen for connections.
#
# @param listen_address
#   The IP Address upon which to listen. Set to 0.0.0.0 to listen on all
#   addresses.
#
# @param drop_rsyslog_noise
#   Ensure that any noise from rsync is dropped. The only items that will be
#   retained will be startup, shutdown, and remote connection activities.
#   Anything from 127.0.0.1 will be dropped as useless.
#
# @param firewall
#   If true, use the SIMP iptables class to manage firewall rules for this
#   module.
#
# @param trusted_nets
#   A list of networks and/or hostnames that are allowed to connect to this
#   service.
#
# @param tcpwrappers
#   Use tcpwrappers to secure the rsync service
#
# @param package_ensure
#   The ensure status of the package to be managed
#
# @param package
#   The rsync daemon package
#
# @author https://github.com/simp/pupmod-simp-rsync/graphs/contributors
#
class rsync::server (
  Boolean          $stunnel            = simplib::lookup('simp_options::stunnel', { default_value => true }),
  Simplib::Port    $stunnel_port       = 8730,
  Simplib::Port    $listen_port        = 873,
  Simplib::IP      $listen_address     = '0.0.0.0',
  Boolean          $drop_rsyslog_noise = true,
  Boolean          $firewall           = simplib::lookup('simp_options::firewall', { default_value => false }),
  Simplib::Netlist $trusted_nets       = simplib::lookup('simp_options::trusted_nets', { default_value => ['127.0.0.1'] }),
  Boolean          $tcpwrappers        = simplib::lookup('simp_options::tcpwrappers', { default_value => false }),
  String           $package_ensure     = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  String           $package,           # module data
) {
  include '::rsync'

  # ensure_resource instead of package resource, because for some OS versions,
  # the client package managed by the rsync class also contains the rsync
  # daemon files.
  ensure_resource('package', $package , { ensure => $package_ensure })

  if $stunnel {
    class { '::rsync::server::global':
      port    => $listen_port,
    }

    include '::stunnel'

    stunnel::connection { 'rsync_server':
      connect      => [$listen_port],
      accept       => "${listen_address}:${stunnel_port}",
      client       => false,
      trusted_nets => $trusted_nets,
      notify       => Service['rsyncd'],
    }

    $_tcp_wrappers_name = 'rsync_server'
  } else {
    class { '::rsync::server::global':
      port    => $listen_port,
      address => $listen_address,
    }

    if $firewall {
      iptables::listen::tcp_stateful { 'allow_rsync_server':
        order        => 11,
        trusted_nets => $trusted_nets,
        dports       => [$listen_port],
      }
    }

    $_tcp_wrappers_name = 'rsync'
  }

  if $tcpwrappers {
    include '::tcpwrappers'

    tcpwrappers::allow { $_tcp_wrappers_name: pattern => $trusted_nets }
  }

  concat { '/etc/rsyncd.conf':
    owner          => 'root',
    group          => 'root',
    mode           => '0400',
    order          => 'numeric',
    ensure_newline => true,
    warn           => true,
    require        => Package[$package]
  }

  if 'systemd' in $facts['init_systems'] {
    service { 'rsyncd':
      ensure     => 'running',
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => Package[$package],
    }
  }
  else {
    file { '/etc/init.d/rsyncd':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      content => file("${module_name}/rsync.init")
    }

    service { 'rsyncd':
      ensure     => 'running',
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => Package[$package],
      provider   => 'redhat',
    }
    File['/etc/init.d/rsyncd'] ~> Service['rsyncd']
  }

  Concat['/etc/rsyncd.conf'] ~> Service['rsyncd']

  if $drop_rsyslog_noise {
    include '::rsyslog'

    rsyslog::rule::drop { '00_rsyncd':
      rule => '$programname == \'rsyncd\' and not ($msg contains \'rsync on\' or $msg contains \'SIG\' or $msg contains \'listening\')'
    }
    rsyslog::rule::drop { '00_rsync_localhost':
      rule => '$programname == \'rsyncd\' and $msg contains \'127.0.0.1\''
    }
  }
}
