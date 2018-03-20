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
  Boolean $sebool_full_access   = false,
  Boolean $sebool_use_nfs       = false,
  Boolean $sebool_use_cifs      = false,
){
  simplib::assert_metadata($module_name)

  package { 'rsync': ensure => 'latest' }

  file { '/etc/rsync':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    purge  => true
  }


  if $facts['selinux_current_mode'] and $facts['selinux_current_mode'] != 'disabled' {
    include rsync::selinux
  }
}
