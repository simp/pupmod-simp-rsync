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
#   This should be either:
#   * A list of usernames that are allowed to connect to this section.
#     ``simplib::passgen()`` will be used to generated random passwords for
#     these users, if they do not already exist in the system
#   * A hash of usernames to their passwords.  If the password is `undef` or 
#     an empty string, ``simplib::passgen()`` will be used to generate or 
#     retrieve it.  
#   In either case, the contents of the auth_users parameter will be ignored 
#   if ``user_pass`` is set.
#
# @param user_pass
#   An optional array of ``username:password`` combinations to be added to the
#   secrets file
#
#   * Not recommended.  Instead, use ``auth_users`` to let the
#     ``simplib::passgen()`` function generate your passwords
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
#   The user ID that transfers should take place as.  Keep in mind that if this 
#   user is non-root, it may cause issues if the user lacks permission to write 
#   out any files that are transferred.
#
# @param gid
#   The group ID that transfers should take place as.  Keep in mind that if this 
#   group is non-root, it may cause issues if the group lacks permission to 
#   write out any files that are transferred.
#
# @param outgoing_chmod
#   A symbolic ``chmod`` that will be applied to files that are transferred
#   outbound
#
# @param ignore_nonreadable
#   Completely ignore any file that is not readable by the user
#
# @param transfer_logging
#   Enable per-file logging of transfers
#
# @param log_format
#   Format used for logging file transfers when transfer logging is enabled
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
  Stdlib::Absolutepath                  $path,
  Optional[Rsync::Auth_users]           $auth_users         = undef,
  Optional[Array[Pattern[/\A.*:.*\z/]]] $user_pass          = undef,
  Optional[String]                      $comment            = undef,
  Boolean                               $use_chroot         = false,
  Integer[0]                            $max_connections    = 0,
  Integer[0]                            $max_verbosity      = 1,
  Stdlib::Absolutepath                  $lock_file          = '/var/run/rsyncd.lock',
  Boolean                               $read_only          = true,
  Boolean                               $write_only         = false,
  Boolean                               $list               = false,
  String                                $uid                = 'root',
  String                                $gid                = 'root',
  String                                $outgoing_chmod     = 'o-w',
  Boolean                               $ignore_nonreadable = true,
  Boolean                               $transfer_logging   = true,
  String                                $log_format         = "'%o %h [%a] %m (%u) %f %l'",
  Array[String]                         $dont_compress      = [
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
  Variant[Enum['*'], Simplib::Netlist] $hosts_allow        = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
  Variant[Enum['*'], Simplib::Netlist] $hosts_deny         = '*'
) {
  include '::rsync::server'

  concat::fragment { "rsync_${name}.section":
    order   => 10,
    target  => '/etc/rsyncd.conf',
    content => template('rsync/rsyncd.conf.section.erb')
  }

  if $auth_users or $user_pass {
    if $user_pass {
      $secretsfile_lines = $user_pass
        .map |$line| { "${line}\n" }
    } else {
      $secretsfile_lines = Hash.assert_type($auth_users) |$ex, $act| {
          $auth_users.reduce({}) |$hash, $user| { $hash + { $user => undef } }
        }.map |$username, $maybe_password| {
        $password = $maybe_password ? {
          String[1] => $maybe_password, # non-empty string: it's a password, use it
          default   => simplib::passgen($username), # undef or '': look up the password
        }

        [$username, ':', $password, "\n"].join
      }
    }

    file { "/etc/rsync/${name}.rsyncd.secrets":
      ensure    => 'file',
      owner     => 'root',
      group     => 'root',
      mode      => '0600',
      content   => $secretsfile_lines.join,
      show_diff => false,
      require   => File['/etc/rsync']
    }
  }
}
