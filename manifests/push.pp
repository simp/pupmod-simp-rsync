# This is simply a call to rsync::retrieve with $pull set to false. It's
# present for clarity and hopefully won't break any dependency chains if you
# use it.
#
# See the documentation for ``rsync::retrieve`` for details.
#
# @param source_path
# @param target_path
# @param rsync_server
# @param proto
# @param rsync_path
# @param preserve_acl
# @param preserve_xattrs
# @param preserve_owner
# @param preserve_group
# @param preserve_devices
# @param exclude
# @param rsync_timeout
# @param logoutput
# @param delete
# @param bwlimit
# @param copy_links
# @param size_only
# @param no_implied_dirs
# @param user
# @param pass
# @param rsubscribe
# @param rnotify
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define rsync::push (
  String                  $source_path,
  String                  $target_path,
  Simplib::Host           $rsync_server,
  String                  $proto            = 'rsync',
  Stdlib::Absolutepath    $rsync_path       = '/usr/bin/rsync',
  Boolean                 $preserve_acl     = true,
  Boolean                 $preserve_xattrs  = true,
  Boolean                 $preserve_owner   = true,
  Boolean                 $preserve_group   = true,
  Boolean                 $preserve_devices = false,
  Array[String]           $exclude          = ['.svn/','.git/'],
  Integer                 $rsync_timeout    = 2,
  Variant[Boolean,String] $logoutput        = 'on_failure',
  Boolean                 $delete           = false,
  Optional[Integer]       $bwlimit          = undef,
  Boolean                 $copy_links       = false,
  Boolean                 $size_only        = false,
  Boolean                 $no_implied_dirs  = true,
  Optional[String]        $user             = undef,
  Optional[String]        $pass             = undef,
  Optional[Catalogentry]  $rsubscribe       = undef,
  Optional[Catalogentry]  $rnotify          = undef
) {
  rsync::retrieve { "push_${name}":
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
    rnotify          => $rnotify,
    bwlimit          => $bwlimit,
    copy_links       => $copy_links,
    size_only        => $size_only,
    no_implied_dirs  => $no_implied_dirs,
    rsubscribe       => $rsubscribe,
    user             => $user,
    pass             => $pass,
    pull             => false
  }
}
