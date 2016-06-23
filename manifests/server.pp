# Class: rsync::server
#
# This class provides a method to set up a fully functioning rsync server.
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
# == Parameters ==
#
# [*drop_rsyslog_noise*]
#   Type: Boolean
#   Default: true
#     If true, ensure that any noise from rsync is dropped. The only
#     items that will be retained will be startup, shutdown, and
#     remote connection activities. Anything from 127.0.0.1 will be
#     dropped as useless.
#
class rsync::server (
  $use_stunnel = true,
  $stunnel_port = '8730',
  $listen_address = '0.0.0.0',
  $drop_rsyslog_noise = true,
  $client_nets = defined('$::client_nets') ? { true => $::client_nets, default => hiera('client_nets', ['127.0.0.1']) }
) {
  validate_bool($drop_rsyslog_noise)
  validate_bool($use_stunnel)
  validate_port($stunnel_port)
  validate_net_list($listen_address)
  validate_net_list($client_nets)

  compliance_map()

  include '::rsync'

  $_subscribe  = $use_stunnel ? {
    true    => Service['stunnel'],
    default => undef
  }

  if $use_stunnel {
    include '::stunnel'

    stunnel::add { 'rsync':
      connect     => ['873'],
      accept      => "${listen_address}:${stunnel_port}",
      client      => false,
      client_nets => $client_nets
    }
  }

  concat_build { 'rsync':
    order   => ['global', '*.section'],
    target  => '/etc/rsyncd.conf',
    require => Package['rsync']
  }

  file { '/etc/rsyncd.conf':
    ensure    => 'file',
    owner     => 'root',
    group     => 'root',
    mode      => '0400',
    audit     => 'content',
    subscribe => Concat_build['rsync'],
    require   => Package['rsync'],
    notify    => Service['rsync']
  }

  file { '/etc/init.d/rsync':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
    source => 'puppet:///modules/rsync/rsync.init'
  }

  service { 'rsync':
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      Package['rsync'],
      File['/etc/rsyncd.conf'],
      File['/etc/init.d/rsync']
    ],
    provider   => 'redhat',
    subscribe  => $_subscribe
  }

  if $drop_rsyslog_noise {
    include '::rsyslog'

    rsyslog::rule::drop { '00_rsyncd':
      rule => 'if ($programname == \'rsyncd\' and not ($msg contains \'rsync on\' or $msg contains \'SIG\' or $msg contains \'listening\'))'
    }
    rsyslog::rule::drop { '00_rsync_localhost':
      rule =>  'if ($programname == \'rsyncd\' and $msg contains \'127.0.0.1\')'
    }
  }
}
