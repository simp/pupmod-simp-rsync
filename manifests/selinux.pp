# This will configure selinux for rsync
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class rsync::selinux {

  $_sebool_anon_write    = $::rsync::sebool_anon_write ? { true => 'on', default => 'off' }
  $_sebool_client        = $::rsync::sebool_client ? { true => 'on', default => 'off' }
  $_sebool_export_all_ro = $::rsync::sebool_export_all_ro ? { true => 'on', default => 'off' }
  $_sebool_full_access   = $::rsync::sebool_full_access ? { true => 'on', default => 'off' }
  $_sebool_use_nfs       = $::rsync::sebool_use_nfs ? { true => 'on', default => 'off' }
  $_sebool_use_cifs      = $::rsync::sebool_use_cifs ? { true => 'on', default => 'off' }

  if $::operatingsystem in ['RedHat','CentOS'] {
    selboolean { 'rsync_client':
      persistent => true,
      value      => $_sebool_client
    }
    selboolean { 'rsync_export_all_ro':
      persistent => true,
      value      => $_sebool_export_all_ro
    }
    if (versioncmp($::operatingsystemmajrelease,'7') < 0){
      selboolean { 'allow_rsync_anon_write':
        persistent => true,
        value      => $_sebool_anon_write
      }
      selboolean { 'rsync_use_cifs':
        persistent => true,
        value      => $_sebool_use_cifs
      }
      selboolean { 'rsync_use_nfs':
        persistent => true,
        value      => $_sebool_use_nfs
      }
    }
    else {
      selboolean { 'rsync_anon_write':
        persistent => true,
        value      => $_sebool_anon_write
      }
      selboolean { 'rsync_full_access':
        persistent => true,
        value      => $_sebool_full_access
      }
    }
  }
  else {
    fail("The rsync class does not yet support ${::operatingsystem}")
  }
}
