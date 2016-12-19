# Provides an rsync client library with a stub exec for certain edge cases
#
# @param sebool_anon_write
#   Allow anonymous rsync users to write to shares
#
#   * Share spaces must be labeled as ``public_content_rw_t``
#   * Only functional if ``selinux`` is not disabled
#
# @param sebool_client
#   Allow rsync to act as a client
#
#   * Only functional if ``selinux`` is not disabled
#
# @param sebool_export_all_ro
#   Allow rsync to export of anything on the system as read only
#
#   * Only functional if ``selinux`` is not disabled
#
# @param sebool_full_access
#   Allow rsync management of **ALL** files on the system
#
#   * Only functional if ``selinux`` is not disabled
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class rsync (
  Boolean $sebool_anon_write    = false,
  Boolean $sebool_client        = true,
  Boolean $sebool_export_all_ro = true,
  Boolean $sebool_full_access   = false
){
  package { 'rsync': ensure => 'latest' }

  file { '/etc/rsync':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    purge  => true
  }

  if $facts['selinux_current_mode'] and $facts['selinux_current_mode'] != 'disabled' {
    $_sebool_anon_write    = $sebool_anon_write ? { true => 'on', default => 'off' }
    $_sebool_client        = $sebool_client ? { true => 'on', default => 'off' }
    $_sebool_export_all_ro = $sebool_export_all_ro ? { true => 'on', default => 'off' }
    $_sebool_full_access   = $sebool_full_access ? { true => 'on', default => 'off' }

    selboolean { 'rsync_anon_write':
      persistent => true,
      value      => $_sebool_anon_write
    }

    selboolean { 'rsync_client':
      persistent => true,
      value      => $_sebool_client
    }

    selboolean { 'rsync_export_all_ro':
      persistent => true,
      value      => $_sebool_export_all_ro
    }

    selboolean { 'rsync_full_access':
      persistent => true,
      value      => $_sebool_full_access
    }
  }
}
