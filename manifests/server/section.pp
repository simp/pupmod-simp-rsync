# Set up a 'section' of /etc/rsyncd.conf pertaining to a particular rsync share.
#
# See rsyncd.conf(5) for descriptions of most variables.
#
# @param name [String] The arbitrary anme of this configuration section.
#
# @param path [AbsolutePath] The directory to make available to clients.
#
# @param auth_users [Array] A list of usernames that are allowed to connect to
#   this section. Passgen() will be used to generated random passwords for
#   these users if they do not already exist in the system.
#
# @param user_pass [Array] An optional array of 'username:password'
#   combinations to be added to the secrets file. It is recommended that you do
#   not set this and instead let the passgen() function generate your
#   passwords.  Entries in this array should be of the following form:
#   'username:password'.
#
# @param comment [String] A comment for the section.
#
# @param use_chroot [Boolean] Use a chroot for this service.
#
# @param max_connections [String] An integer that represents the maximum number
#   of connections allowed to this service.
#
# @param max_verbosity [String] An integer that represents the logging
#   verbosity that the daemon should use for connections to this service.
#
# @param lock_file [AbsolutePath] The path to the lock file for this service.
#
# @param read_only [Boolean] Do not allow clients to write to this share.
#
# @param write_only [Boolean] Only allow clients to write to this share.
#
# @param list [Boolean] List this share when clients ask for a list of
#   available modules.
#
# @param uid [String] The user ID that transfers should take place as. Must
#   have access to all of the relevant files.
#
# @param gid [String] The group ID that transfers should take place as. Must
#   have access to all of the relevant files.
#
# @param outgoing_chmod [String] A symbolic chmod that will be applied to files
#   that are transferred outbound.
#
# @param ignore_noreadable [Boolean] Completely ignore any file that is not
#   readable by the user.
#
# @param transfer_logging [Boolean] Enable per-file logging of transfers.
#
# @param dont_compress [Array] An Array of filenames and globs that should not
#   be compressed upon transfer.
#
# @param hosts_allow [NetList] An Array of hosts that should be allowed to
#   connect to this share. Set to ['127.0.0.1'] if using stunnel for the
#   overall system. Can also be set to the String '*' to allow all hosts.
#
# @param hosts_deny [NetList] An array of hosts to explicitly deny from
#   connection to this share. Should be set to the String '*' as it is
#   overridden by $hosts_allow.
#
define rsync::server::section (
  $path,
  $auth_users = '',
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
  $hosts_allow = lookup('client_nets', Array, 'first', ['127.0.0.1']),
  $hosts_deny = '*'
) {
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

  include '::rsync::server'

  concat::fragment { "rsync_${name}.section":
    order   => '10',
    target  => '/etc/rsyncd.conf',
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
}
