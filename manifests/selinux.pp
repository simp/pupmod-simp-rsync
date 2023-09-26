# This will configure selinux for rsync
#
# @author https://github.com/simp/pupmod-simp-selinux/graphs/contributors
#
class rsync::selinux {
  $_sebool_anon_write    = $rsync::sebool_anon_write ? { true => 'on', default => 'off' }
  $_sebool_client        = $rsync::sebool_client ? { true => 'on', default => 'off' }
  $_sebool_export_all_ro = $rsync::sebool_export_all_ro ? { true => 'on', default => 'off' }
  $_sebool_full_access   = $rsync::sebool_full_access ? { true => 'on', default => 'off' }

  selboolean { 'rsync_client':
    persistent => true,
    value      => $_sebool_client
  }
  selboolean { 'rsync_export_all_ro':
    persistent => true,
    value      => $_sebool_export_all_ro
  }
  selboolean { 'rsync_anon_write':
    persistent => true,
    value      => $_sebool_anon_write
  }
  selboolean { 'rsync_full_access':
    persistent => true,
    value      => $_sebool_full_access
  }
}
