# Class: rsync
#
# This class provides an rsync client library with a stub exec for certain edge
# cases.
class rsync {
  package { 'rsync': ensure => 'latest' }

  file { '/etc/rsync':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    purge  => true
  }

  if $::selinux_current_mode and $::selinux_current_mode != 'disabled' {
    selboolean { 'rsync_client':
      persistent => true,
      value      => 'on'
    }
    selboolean { 'rsync_export_all_ro':
      persistent => true,
      value      => 'on'
    }
  }
}
