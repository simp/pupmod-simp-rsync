# Setup the global section of /etc/rsyncd.conf.
#
# See ``rsyncd.conf(5)`` for details of parameters not listed below.
#
# @param motd_file
#   The path to the default MOTD file that should be displayed upon connection
#
# @param pid_file
#   The path to the service PID file
#
# @param syslog_facility
#   A valid syslog ``facility`` to use for logging
#
# @param port
#   The port upon which to listen for client connections
#
# @param address
#   The IP address upon which to listen for connections
#
#   * Leave this at ``127.0.0.1`` if using stunnel
#
# @param trusted_nets
#   The networks to allow to connect to this service
#
#
# @param tcpwrappers
#   Use tcpwrappers to secure the rsync service
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class rsync::server::global (
  Optional[Stdlib::Absolutepath] $motd_file       = undef,
  Stdlib::Absolutepath           $pid_file        = '/var/run/rsyncd.pid',
  String                         $syslog_facility = 'daemon',
  Simplib::Port                  $port            = 873,
  Simplib::IP                    $address         = '127.0.0.1',
  Simplib::Netlist               $trusted_nets    = simplib::lookup('simp_options::trusted_nets', { default_value => ['127.0.0.1'] }),
  Boolean                        $tcpwrappers     = simplib::lookup('simp_options::tcpwrappers', { default_value => false })
) {

  if $tcpwrappers {
    include '::tcpwrappers'

    tcpwrappers::allow { 'rsync': pattern => $trusted_nets }
  }

  concat::fragment { 'rsync_global':
    order   => 5,
    target  => '/etc/rsyncd.conf',
    content => template("${module_name}/rsyncd.conf.global.erb")
  }
}
