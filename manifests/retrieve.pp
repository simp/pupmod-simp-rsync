# Retrieve a file over the rsync protocol.
# See rsync(1) for details of most options.
#
# @param source_path [String] The path *on the rsync server* from which to
#   retrieve files. This will, most likely, not start with a forward slash.
#
# @param target_path [AbsolutePath] The path to which to write on the client
#   system.
#
# @param rsync_server [Hostname] The host to which to connect.
#
# @param proto [String] The protocol to use. You probably won't change this.
#
# @param rsync_path [AbsolutePath] The path to the 'rsync' command.
#
# @param preserve_acl [Boolean] Preserve the ACL from the server.
#
# @param preserve_xattrs [Boolean] Preserve the extended attributes from the
#   server.
#
# @param preserve_owner [Boolean] Preserve the file owner from the server.
#
# @param preserve_group [Boolean] Preserve the file group from the server.
#
# @param preserve_devices [Boolean] Preserve device special IDs from the server.
#
# @param exclude [Array] Paths and globs to exclude from transfers.
#
# @param rsync_timeout [String] An Integer that is the number of seconds to
#   wait for a transfer to begin before timing out.
#
# @param  logoutput [String] Log the output of the rsync run at the provided trigger.
#
# @param  delete [Boolean] Delete local files that do not exist on the remote
#   server.
#
# @param  rnotify [String] Wrap a notify so that this process will send a
#   Puppet notification to a resource after completion. Use like the regular
#   Puppet ``notify`` meta-parameter.
#
# @param bwlimit [String] The bandwidth limit for the connection.
#
# @param copy_links [Boolean] Copy symlinks as symlinks during the transfer.
#
# @param size_only [Boolean] Only compare files by size to determine if they
#   need a transfer.
#
# @param no_implied_dirs [Boolean] Don't send implied directories with relative
#   pathnames.
#
# @param  rsubscribe [String] Wrap a subscribe so that this process will
#   subscribe to a Puppet resource after completion. Use like the regular
#   Puppet ``subscribe`` meta-parameter.
#
# @param user [String] The username to use when connecting to the server.
#
# @param pass [String] The password to use when connecting to the server. If
#   left blank, and a username is provided, the passgen() function willi be
#   used to look up the password.
#
# @param pull [Boolean] Pull files from the remote server. If set to ``false``
#   will push files to the server instead of pulling them from the server.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define rsync::retrieve (
  $source_path,
  $target_path,
  $rsync_server     = lookup('rsync::server'),
  $proto            = 'rsync',
  $rsync_path       = '/usr/bin/rsync',
  $preserve_acl     = true,
  $preserve_xattrs  = true,
  $preserve_owner   = true,
  $preserve_group   = true,
  $preserve_devices = false,
  $exclude          = ['.svn/','.git/'],
  $rsync_timeout    = '2',
  $logoutput        = 'on_failure',
  $delete           = false,
  $rnotify          = undef,
  $bwlimit          = lookup('rsync::bwlimit', String, 'first', ''),
  $copy_links       = false,
  $size_only        = false,
  $no_implied_dirs  = true,
  $rsubscribe       = undef,
  $user             = '',
  $pass             = '',
  $pull             = true
) {

  validate_absolute_path($rsync_path)
  validate_bool($preserve_acl)
  validate_bool($preserve_xattrs)
  validate_bool($preserve_owner)
  validate_bool($preserve_group)
  validate_bool($preserve_devices)
  validate_integer($rsync_timeout)
  validate_bool($delete)
  validate_bool($copy_links)
  validate_bool($size_only)
  validate_bool($no_implied_dirs)
  validate_bool($pull)

  include '::rsync'

  # This is some hackery to allow a global variable to exist but
  # override it with a local variable if it's present.
  if !empty($bwlimit) {
    $_bwlimit = $bwlimit
  }
  else {
    $_bwlimit = undef
  }

  $_user = $user ? {
    ''      => undef,
    default => $user
  }

  $_pass = $pass ? {
    ''      => undef,
    default => $pass ? {
      ''      => passgen($user),
      default => $pass
    }
  }

  $_action = $pull ? {
    false   => 'push',
    default => 'pull'
  }

  rsync { $name:
    source_path      => $source_path,
    target_path      => $target_path,
    rsync_server     => $rsync_server,
    proto            => $proto,
    rsync_path       => $rsync_path,
    preserve_acl     => $preserve_acl,
    preserve_xattrs  => $preserve_xattrs,
    preserve_owner   => $preserve_owner,
    preserve_group   => $preserve_group,
    preserve_devices => $preserve_devices,
    exclude          => $exclude,
    rsync_timeout    => $rsync_timeout,
    logoutput        => $logoutput,
    delete           => $delete,
    bwlimit          => $_bwlimit,
    copy_links       => $copy_links,
    size_only        => $size_only,
    no_implied_dirs  => $no_implied_dirs,
    subscribe        => $rsubscribe,
    notify           => $rnotify,
    user             => $_user,
    pass             => $_pass,
    action           => $_action
  }
}
