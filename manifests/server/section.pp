# _Description_
#
# Set up a 'section' of /etc/rsyncd.conf pertaining to a particular rsync share.
#
# See rsyncd.conf(5) for descriptions of most variables.
#
define rsync::server::section (
# _Variables_
#
# $name
#     Becomes the name of the temporary file that will be part of a multi-part
#     build file.
#     Note: Do not add a '/' to the contents of the name variable.
#
  $path,
# $auth_users
#     Set this to an array of allowed usernames for this section.
#
  $auth_users = '',
# $user_pass
#     An array of 'username:password' combinations to be added to the secrets
#     file. It is recommended that you use the included passgen function to
#     generate the passwords. If $user_pass is left blank but $auth_users is
#     set, then random passwords will be generated for you.
#
  $user_pass = '',
  $comment = '',
  $use_chroot = false,
  $max_connections = '0',
  $max_verbosity = '1',
  $lock_file = '/var/run/rsyncd.lock',
  $read_only = true,
  $write_only = false,
  $list = false,
  $uid = 'root',
  $gid = 'root',
  $outgoing_chmod = 'o-w',
  $ignore_nonreadable = true,
  $transfer_logging = true,
  $log_format = "'%o %h [%a] %m (%u) %f %l'",
  $dont_compress = [
    '*.gz',
    '*.tgz',
    '*.zip',
    '*.z',
    '*.rpm',
    '*.deb',
    '*.iso',
    '*.bz2',
    '*.tbz',
    '*.rar',
    '*.jar',
    '*.pdf',
    '*.sar',
    '*.war'
  ],
  $hosts_allow = $client_nets,
  $hosts_deny = '*'
) {
  include 'rsync::server'

  concat_fragment { "rsync+$name.section":
    content => template('rsync/rsyncd.conf.section.erb')
  }

  if !empty($auth_users) {
    file { "/etc/rsync/${name}.rsyncd.secrets":
      ensure  => 'file',
      owner   => $uid,
      group   => $gid,
      mode    => '0600',
      content => template('rsync/secrets.erb'),
      require => File['/etc/rsync']
    }
  }

  if !empty($auth_users) { validate_array($auth_users) }
  if !empty($user_pass) { validate_array($user_pass) }
  validate_bool($use_chroot)
  validate_integer($max_connections)
  validate_integer($max_verbosity)
  validate_absolute_path($lock_file)
  validate_bool($read_only)
  validate_bool($write_only)
  validate_bool($list)
  validate_bool($ignore_nonreadable)
  validate_array($dont_compress)
  validate_bool($transfer_logging)
  validate_net_list($hosts_allow,'*')
  validate_net_list($hosts_deny,'*')
}
