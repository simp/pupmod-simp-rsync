# Setup the global section of /etc/rsyncd.conf.
#
# See ``rsyncd.conf(5)`` for details of parameters not listed below.
#
# @param port
#   The port upon which to listen for client connections
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
# @param address
#   The IP address upon which to listen for connections
#
#   * Leave this at ``127.0.0.1`` if using stunnel
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class rsync::server::global (
  Simplib::Port                  $port,
  Optional[Stdlib::Absolutepath] $motd_file       = undef,
  Stdlib::Absolutepath           $pid_file        = '/var/run/rsyncd.pid',
  String                         $syslog_facility = 'daemon',
  Simplib::IP                    $address         = '127.0.0.1',
) {
  assert_private()

  if $facts['selinux_current_mode'] and $facts['selinux_current_mode'] != 'disabled' {
    vox_selinux::port { "allow_rsync_port_${port}":
      ensure   => 'present',
      seltype  => 'rsync_port_t',
      protocol => 'tcp',
      port     => $port,
    }
  }

  concat::fragment { 'rsync_global':
    order   => 5,
    target  => '/etc/rsyncd.conf',
    content => template("${module_name}/rsyncd.conf.global.erb")
  }
}
