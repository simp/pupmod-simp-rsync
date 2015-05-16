Puppet::Type.newtype(:rsync) do
  @doc = <<-EOM
    Run an rsync command; almost all options are directly from the rsync man
    page.

    Though we've done what we can to mimize SELinux impact. If you have the
    situation where your Puppet server's rsync space does *not* have SELinux
    attributes but your client is Permissive or Enforcing. Then you will most
    certainly see error messages of the type that extended attributes have
    changed.

    Your best bet is to ensure that your Puppet server runs in at least
    Permissive mode. If you need to refresh your rsync data attributes, then
    running 'fixfiles -R simp-rsync restore'.
  EOM

  def initialize(args)
    super

    self.tags = [Array(self.tags),'rsync'].flatten
  end

  def finish
    super
  end

  newparam(:name) do
    isnamevar
  end

  newparam(:ignore_selinux) do
    desc <<-EOM
      If this is set to 'true' then this type will ignore SELinux errors. If
      set to false, then an SELinux permissions copy error is a complete
      failure state.
    EOM

    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:password) do
    desc <<-EOM
      The password to use. Only used if a username is specified
      If you want the password to be auto-generated, you can use the
      SIMP 'passgen' function.

        $user = 'foo'

        rsync::retrieve { \"foo\":
          source   => 'bar',
          target   => '/tmp/foo',
          server   => 'puppet',
          user     => $user,
          password => passgen($user)
        }
     EOM
  end

  newparam(:pass) do
    desc <<-EOM
      The password to use. Only used if a username is specified
      If you want the password to be auto-generated, you can use the
      SIMP 'passgen' function.

        $user = 'foo'

        rsync::retrieve { \"foo\":
          source   => 'bar',
          target   => '/tmp/foo',
          server   => 'puppet',
          user     => $user,
          password => passgen($user)
        }
     EOM
  end

  newproperty(:action) do
    desc 'Whether to push or pull from rsync server. Defaults to pull'
    newvalues(:push, :pull)
    defaultto :pull

    def insync?(is)
      provider.action_insync?
    end

    def change_to_s(currentvalue, newvalue)
      'executed successfully'
    end
  end

  newparam(:source) do
    desc 'The fully qualified source path on the rsync server'
  end

  newparam(:source_path) do
    desc 'The fully qualified source path on the rsync server'
  end

  newparam(:target) do
    desc 'The fully qualified target path on the rsync client'
  end

  newparam(:target_path) do
    desc 'The fully qualified target path on the rsync client'
  end

  newparam(:server) do
    desc 'The hostname or IP of the rsync server'

    validate do |value|
      if value !~ /[a-zA-Z][a-zA-Z\-]*(\.[a-zA-Z][a-zA-Z\-]*)*/
        begin
          require 'ipaddr'
          IPAddr.new(value)
        rescue Exception
          fail Puppet::Error, %(#{value} does not appear to be a valid hostname or IP address)
        end
      end
    end
  end

  newparam(:rsync_server, :parent => self.paramclass(:server)) do
    desc 'The hostname or IP of the rsync server'
  end

  newparam(:proto) do
    desc 'The protocol to use in connecting to the rsync server. Defaults to "rsync"'
  end

  newparam(:protocol) do
    desc 'The protocol to use in connecting to the rsync server. Defaults to "rsync"'
  end

  newparam(:rsync_path) do
    desc 'The fully qualified path to the rsync executable'
  end

  newparam(:path) do
    desc 'The fully qualified path to the rsync executable'
  end

  newparam(:preserve_acl, :boolean => true) do
    desc 'Whether or not to preserve ACL. Defaults to true.'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:preserve_xattrs, :boolean => true) do
    desc 'Whether or not to preserve extended attributes. Defaults to true.'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:preserve_owner, :boolean => true) do
    desc 'Whether or not to preserve owner. Defaults to true.'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:preserve_group, :boolean => true) do
    desc 'Whether or not to preserve group. Defaults to true.'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:preserve_devices, :boolean => true) do
    desc 'Whether or not to preserve device files. Defaults to false.'
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:compress, :boolean => true) do
    desc 'Whether or not to compress content prior to transfer. Defaults to true.'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:recurse, :boolean => true) do
    desc 'Whether or not to recursively copy. Defaults to true.'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:hard_links, :boolean => true) do
    desc 'Preserve hard links. Defaults to true.'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:exclude) do
    desc <<-EOM
      Exclude files matching PATTERN.  Multiple values may be specified as an
      array.  Defaults to ['.svn/','.git/']
    EOM

    munge do |value|
      [value].flatten
    end
    defaultto ['.svn/','.git/']
  end

  newparam(:timeout) do
    desc <<-EOM
      Connection timeout in seconds. Note: This is different from what the man
      page states due to backward compatibility issues. Use iotimeout for the
      man page compatible timeout value.
     EOM

    munge do |value|
      if value.is_a?(String)
        unless value =~ /^\d+$/
          fail Puppet::Error, 'Timeout must be an integer'
        end
        Integer(value)
      else
        value
      end
    end
  end

  newparam(:contimeout, :parent => self.paramclass(:timeout)) do
    desc 'Connection timeout in seconds.'
  end

  newparam(:rsync_timeout, :parent => self.paramclass(:contimeout))

  newparam(:iotimeout, :parent => self.paramclass(:timeout)) do
    desc 'I/O timeout in seconds.'
  end

  newparam(:logoutput) do
    desc <<-EOM
      Whether to log output.  Defaults to logging output at the loglevel for
      the `exec` resource. Use *on_failure* to only log the output when the
      command reports an error.  Values are **true**, *false*, *on_failure*,
      and any legal log level.
    EOM

    newvalues(:true, :false, :on_failure)
    defaultto :on_failure
  end

  newparam(:delete, :boolean => true) do
    desc 'Whether to delete files that do not exist on server. Defaults to false'
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:bwlimit) do
    desc 'KB/s to limit I/O bandwidth to'

    munge do |value|
      if value.is_a?(String)
        unless value =~ /^\d+$/
          fail Puppet::Error, 'bwlimit must be an integer'
        end
        Integer(value)
      else
        value
      end
    end
  end

  newparam(:copy_links, :boolean => true) do
    desc 'Whether to copy links as symlinks. Defaults to false'
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:size_only, :boolean => true) do
    desc 'Whether to skip files that match in size. Defaults to true'
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:no_implied_dirs, :boolean => true) do
    desc 'Do not send implied dirs.  Defaults to true'
    newvalues(:true, :false)
    defaultto :true
  end

  newparam(:user) do
    desc 'The username to use'
  end

  autorequire(:user) do
    # Autorequire users if they are specified by name
    if user = self[:user] && user !~ /^\d+$/
      debug %(Autorequiring User[#{user}])
      user
    end
  end

  autorequire(:file) do
    path = []
    path << '/etc/rsync'

    if !self[:server]
      path << self[:target]
      path << self[:source]
    elsif self[:action] == :pull or self[:action].eql?('pull')
      path << self[:target]
    else
      path << self[:source]
    end

    path.each do |val|
      debug %(Autorequiring File[#{val}])
    end

    path
  end

  autorequire(:tidy) do
    path = ['/etc/rsync']

    path.each do |val|
      debug %(Autorequiring Tidy[#{val}])
    end

    path
  end

  autorequire(:selboolean) do
    bools = ['rsync_client']

    bools.each do |val|
      debug %(Autorequiring Selboolean[#{val}])
    end

    bools
  end

  autorequire(:service) do
    svcs = ['rsync','stunnel']

    svcs.each do |val|
      debug %(Autorequiring Service[#{val}])
    end

    svcs
  end

  validate do
    required_fields = [[:source, :source_path], [:target, :target_path]]
    aliases = [
      [:source, :source_path],
      [:target, :target_path],
      [:server, :rsync_server],
      [:protocol, :proto],
      [:timeout, :rsync_timeout],
      [:timeout, :contimeout],
      [:password, :pass]
    ]

    unless @parameters.include?(:protocol) || @parameters.include?(:proto)
      self[:protocol] = "rsync"
    end

    unless @parameters.include?(:timeout) || @parameters.include?(:rsync_timeout)
      fail Puppet::Error, "You must specify an rsync timeout."
    end

    required_fields.each do |req|
      unless @parameters.include?(req.first) || @parameters.include?(req.last)
        fail Puppet::Error, "You must specify one of #{req.first} or #{req.last}."
      end
    end

    aliases.each do |a|
      if @parameters.include?(a.first) && @parameters.include?(a.last)
        fail Puppet::Error, %(You can only specify one of #{a.first} and #{a.last})
      end
    end

    if (self[:server] || self[:rsync_server]) && self[:action] == :pull
      full_paths = [:path, :rsync_path, :target, :target_path]
    elsif self[:server] || self[:rsync_server]
      full_paths = [:path, :rsync_path, :source, :source_path]
    else
      full_paths = [:path, :rsync_path, :source, :source_path, :target, :target_path]
    end

    full_paths.each do |path|
      if self[path]
        unless self[path] =~ /^\/$/ || self[path] =~ /^\/[^\/]/
          fail Puppet::Error, %(File paths must be fully qualified, not '#{self[path]}')
        end
      end
    end

    unless @parameters.include?(:server) || @parameters.include?(:rsync_server)
      if @parameters.include?(:protocol) || @parameters.include?(:proto)
        debug 'Protocol set without server, ignoring.'
        @parameters.delete(:protocol)
        @parameters.delete(:proto)
      end

      if @parameters.include?(:user)
        debug 'User set without server, ignoring.'
        @parameters.delete(:user)
      end

      if @parameters.include?(:password) || @parameters.include?(:pass)
        debug 'Password set without server, ignoring.'
        @parameters.delete(:password)
        @parameters.delete(:pass)
      end
    end

    unless @parameters.include?(:user)
      if @parameters.include?(:password) || @parameters.include?(:pass)
        debug 'Password set without user, ignoring.'
        @parameters.delete(:password)
        @parameters.delete(:pass)
      end
    end

    if @parameters.include?(:user) &&
       !(@parameters.include?(:password) || @parameters.include?(:pass))
    then
      fail Puppet::Error, 'You must specify a password if you specify a user.'
    end
  end
end
