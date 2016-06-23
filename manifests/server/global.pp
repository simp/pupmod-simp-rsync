# == Class: rsync::server::global
#
# Setup the global section of /etc/rsyncd.conf.
# Note that the $address defaults to 127.0.0.1.
# Set to '' or 0.0.0.0 to listen on all interfaces.
#
# See rsyncd.conf(5) for details of parameters not listed below.
#
# == Parameters
#
# [*client_nets*]
# Type: Array of Networks or 'ALL' for all networks
# Default: ALL
#   The networks to allow to connect ot the rsync service.
#
# == Authors
#   * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class rsync::server::global (
  $motd_file = '',
  $pid_file = '/var/run/rsyncd.pid',
  $syslog_facility = 'daemon',
  $port = '873',
  $address = '127.0.0.1',
  $client_nets = 'ALL'
) {
  validate_absolute_path($pid_file)
  validate_port($port)
  validate_net_list($address)
  validate_net_list($client_nets,'ALL')

  compliance_map()

  include '::tcpwrappers'

  concat_fragment { 'rsync+global':
    content => template('rsync/rsyncd.conf.global.erb')
  }

  tcpwrappers::allow { 'rsync': pattern => $client_nets }
}
