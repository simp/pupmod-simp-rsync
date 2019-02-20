# Retrieve a file over the rsync protocol
#
# @see rsync(1)
#
# @param source_path
#   The path *on the rsync server* from which to retrieve files
#
#   * This will, most likely, not start with a forward slash
#
# @param target_path
#   The path to which to write on the client system
#
# @param rsync_server
#   The host to which to connect
#
# @param proto
#   The protocol to use
#
#   * This will go before the ``://`` in the rsync connection string
#   * You probably won't change this
#
# @param rsync_path
#   The path to the 'rsync' command
#
# @param preserve_acl
#   Preserve the file ACLs from the server
#
# @param preserve_xattrs
#   Preserve the extended attributes from the server
#
# @param preserve_owner
#   Preserve the file owner from the server
#
# @param preserve_group
#   Preserve the file group from the server
#
# @param preserve_devices
#   Preserve device special IDs from the server
#
# @param exclude
#   Paths and globs to exclude from transfers
#
# @param rsync_timeout
#   The number of seconds to wait for a transfer to begin before timing out
#
# @param logoutput
#   Log the output of the rsync run at the provided trigger
#
# @param delete
#   Delete local files that do not exist on the remote server
#
# @param bwlimit
#   The bandwidth limit for the connection
#
# @param copy_links
#   Preserve symlinks during the transfer
#
# @param size_only
#   Only compare files by size to determine if they need a transfer
#
# @param no_implied_dirs
#   Don't send implied directories with relative pathnames
#
# @param user
#   The username to use when connecting to the server
#
# @param pass
#   The password to use when connecting to the server
#
#   * If left blank, and a username is provided, the ``simplib::passgen()``
#     function will be used to look up the password
#
# @param pull
#   Pull files from the remote server
#
#   * If set to ``false``, will push files to the server instead of pulling
#   them from the server
#
# @param rnotify
#   Wrap a ``notify`` so that this process will send a Puppet notification to a
#   resource after completion
#
#   * Use like the regular Puppet ``notify`` meta-parameter
#
# @param rsubscribe
#   Wrap a ``subscribe`` so that this process will subscribe to a Puppet
#   resource after completion
#
#   * Use like the regular Puppet ``subscribe`` meta-parameter
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define rsync::retrieve (
  String                                      $source_path,
  String                                      $target_path,
  Variant[Simplib::Host, Simplib::Host::Port] $rsync_server     = simplib::lookup('simp_options::rsync::server'),
  String                                      $proto            = 'rsync',
  Stdlib::Absolutepath                        $rsync_path       = '/usr/bin/rsync',
  Boolean                                     $preserve_acl     = true,
  Boolean                                     $preserve_xattrs  = true,
  Boolean                                     $preserve_owner   = true,
  Boolean                                     $preserve_group   = true,
  Boolean                                     $preserve_devices = false,
  Array[String]                               $exclude          = ['.svn/','.git/'],
  Integer[0]                                  $rsync_timeout    = 2,
  String                                      $logoutput        = 'on_failure',
  Boolean                                     $delete           = false,
  Optional[String]                            $bwlimit          = simplib::lookup('rsync::bwlimit', { 'default_value' => undef }),
  Boolean                                     $copy_links       = false,
  Boolean                                     $size_only        = false,
  Boolean                                     $no_implied_dirs  = true,
  Optional[String]                            $user             = undef,
  Optional[String]                            $pass             = undef,
  Boolean                                     $pull             = true,
  Optional[Catalogentry]                      $rnotify          = undef,
  Optional[Catalogentry]                      $rsubscribe       = undef
) {
  include '::rsync'

  if $pass {
    $_pass = $pass
  }
  else {
    if $user {
      $_pass = simplib::passgen($user)
    }
    else {
      $_pass = undef
    }
  }

  $_action = $pull ? { false => 'push', default => 'pull' }

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
    bwlimit          => $bwlimit,
    copy_links       => $copy_links,
    size_only        => $size_only,
    no_implied_dirs  => $no_implied_dirs,
    subscribe        => $rsubscribe,
    notify           => $rnotify,
    user             => $user,
    pass             => $_pass,
    action           => $_action
  }
}
