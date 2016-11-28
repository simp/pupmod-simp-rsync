# Setup the global section of /etc/rsyncd.conf.
#
# See ``rsyncd.conf(5)`` for details of parameters not listed below.
#
# @param motd_file [AbsolutePath] The path to the MOTD file that should be
#   displayed upon connection to any service.
#
# @param pid_file [AbsolutePath] The path to the service PID file.
#
# @param syslog_facility [SyslogFacility] A valid syslog facility to use for logging.
#
# @param port [Port] The port upon which to listen for client connections.
#
# @param address [IPAddress] The IP address upon which to listen for
#   connections. Leave this at ``127.0.0.1`` if using stunnel.
#
# @param client_nets [NetList] The networks to allow to connect to this service
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

  include '::tcpwrappers'

  concat::fragment { 'rsync_global':
    order   => '5',
    target  => '/etc/rsyncd.conf',
    content => template("${module_name}/rsyncd.conf.global.erb")
  }

  tcpwrappers::allow { 'rsync': pattern => $client_nets }
}
