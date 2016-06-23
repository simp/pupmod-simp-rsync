# _Description_
#
# Retrieve a file over the rsync protocol.
# See rsync(1) for details of most options.
#
# _Global_Variables_
#
# * $rsync_bwlimit
#
# _Templates_
define rsync::retrieve (
# _Variables_
    $source_path,
    $target_path,
# This is silly, but it catches both cases.
    $rsync_server = hiera('rsync::server'),
    $proto = 'rsync',
    $rsync_path = '/usr/bin/rsync',
    $preserve_ACL = true,
    $preserve_xattrs = true,
    $preserve_owner = true,
    $preserve_group = true,
    $preserve_devices = false,
    $exclude = ['.svn/','.git/'],
    $rsync_timeout = '2',
# $logoutput
#     Whether or not to log the output of the rsync run.
#
    $logoutput = 'on_failure',
    $delete = false,
# $rnotify
#     'rsync notify' - This allows you to wrap a notify so that this process
#     will send a Puppet notification to an object after completion. Use just
#     like the normal 'notify' meta-parameter.
#
    $rnotify = undef,
    $bwlimit = hiera('rsync::bwlimit',''),
    $copy_links = false,
    $size_only = false,
    $no_implied_dirs = true,
# $rsubscribe
#     'rsync subscribe' - This allows you to wrap a subscribe so that this
#     process will set up a Puppet subscription. Use like the normal
#     'subscribe' meta-parameter.
#
    $rsubscribe = undef,
# $user
#     The username to use
#
    $user = '',
# $pass
#     The password to use, if left blank, the passgen function will be used to
#     look up the password. This will only be used if a username is specified.
#
    $pass = '',
# $pull
#     Whether to pull or push. Pull is the default. Setting this to 'false'
#     will allow you to push files back to the rsync server if the server has
#     been configured to allow it.
    $pull = true
  ) {
  validate_absolute_path($rsync_path)
  validate_bool($preserve_ACL)
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
    $lbwlimit = $bwlimit
  }
  else {
    $lbwlimit = undef
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
    preserve_acl     => $preserve_ACL,
    preserve_xattrs  => $preserve_xattrs,
    preserve_owner   => $preserve_owner,
    preserve_group   => $preserve_group,
    preserve_devices => $preserve_devices,
    exclude          => $exclude,
    rsync_timeout    => $rsync_timeout,
    logoutput        => $logoutput,
    delete           => $delete,
    bwlimit          => $lbwlimit,
    copy_links       => $copy_links,
    size_only        => $size_only,
    no_implied_dirs  => $no_implied_dirs,
    subscribe        => $rsubscribe,
    notify           => $rnotify,
    user             => $_user,
    pass             => $_pass,
    action           => $_action,
  }
}
