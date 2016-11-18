# _Description_
#
# This is simply a call to rsync::retrieve with $pull set to false. It's
# present for clarity and hopefully won't break any dependency chains if you
# use it.
#
# See the documentation for rsync::retrieve for details.
#
define rsync::push (
# _Variables_
    $source_path,
    $target_path,
    $rsync_server,
    $proto = 'rsync',
    $rsync_path = '/usr/bin/rsync',
    $preserve_acl = true,
    $preserve_xattrs = true,
    $preserve_owner = true,
    $preserve_group = true,
    $preserve_devices = false,
    $exclude = ['.svn/','.git/'],
    $rsync_timeout = '2',
    $logoutput = 'on_failure',
    $delete = false,
    $rnotify = '',
    $bwlimit = '',
    $copy_links = false,
    $size_only = false,
    $no_implied_dirs = true,
    $rsubscribe = undef,
    $user = '',
    $pass = ''
  ) {

  rsync::retrieve { "pull_${name}":
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
