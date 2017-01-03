# Set up a 'section' of /etc/rsyncd.conf pertaining to a particular rsync share.
#
# See ``rsyncd.conf(5)`` for descriptions of most variables.
#
# @param name
#   The arbitrary name of this configuration section
#
# @param path
#   The directory to make available to clients
#
# @param auth_users
#   A list of usernames that are allowed to connect to this section
#
#   * ``passgen()`` will be used to generated random passwords for these users
#     if they do not already exist in the system
#
# @param user_pass
#   An optional array of ``username:password`` combinations to be added to the
#   secrets file
#
#   * It is recommended that you do not set this and instead let the
#     ``passgen()`` function generate your passwords
#   * Entries in this Array should be of the following form:
#     ``username:password``
#
# @param comment
#   A comment for the section
#
# @param use_chroot
#   Use a ``chroot`` for this service
#
# @param max_connections
#   The maximum number of connections allowed
#
# @param max_verbosity
#   The logging verbosity that the daemon should use for connections to this
#   service
#
# @param lock_file
#   The path to the lock file for this service
#
# @param read_only
#   Do not allow clients to write to this share
#
# @param write_only
#   Only allow clients to write to this share
#
# @param list
#   List this share when clients ask for a list of available modules
#
# @param uid
#   The user ID that transfers should take place as
#
#   * This user must have access to all of the relevant files
#
# @param gid
#   The group ID that transfers should take place as
#
#   * Must have access to all of the relevant files
#
# @param outgoing_chmod
#   A symbolic ``chmod`` that will be applied to files that are transferred
#   outbound
#
# @param ignore_noreadable
#   Completely ignore any file that is not readable by the user
#
# @param transfer_logging
#   Enable per-file logging of transfers
#
# @param dont_compress
#   Filenames and globs that should not be compressed upon transfer
#
# @param hosts_allow
#   Hosts that should be allowed to connect to this share
#
#   * Set to ``['127.0.0.1']`` if using ``stunnel`` for the overall system
#   * May also be set to the String ``*`` to allow all hosts
#
# @param hosts_deny
#   Hosts to explicitly deny from connection to this share
#
#   * Should be set to the String ``*`` as it is overridden by ``$hosts_allow``
#
define rsync::server::section (
  Stdlib::Absolutepath                 $path,
  Optional[Array[String]]              $auth_users         = undef,
  Optional[Array[String]]              $user_pass          = undef,
  Optional[String]                     $comment            = undef,
  Boolean                              $use_chroot         = false,
  Integer[0]                           $max_connections    = 0,
  Integer[0]                           $max_verbosity      = 1,
  Stdlib::Absolutepath                 $lock_file          = '/var/run/rsyncd.lock',
  Boolean                              $read_only          = true,
  Boolean                              $write_only         = false,
  Boolean                              $list               = false,
  String                               $uid                = 'root',
  String                               $gid                = 'root',
  String                               $outgoing_chmod     = 'o-w',
  Boolean                              $ignore_nonreadable = true,
  Boolean                              $transfer_logging   = true,
  String                               $log_format         = "'%o %h [%a] %m (%u) %f %l'",
  Array[String]                        $dont_compress      = [
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
  Variant[Enum['*'], Simplib::Netlist] $hosts_allow        = simplib::lookup{ 'simp_options::trusted_nets'{ 'default_value' => ['127.0.0.1'] }),
  Variant[Enum['*'], Simplib::Netlist] $hosts_deny         = '*'
) {
  include '::rsync::server'

  concat::fragment { "rsync_${name}.section":
    order   => 10,
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
