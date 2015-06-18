Puppet::Type.type(:rsync).provide :rsync do
  require 'tempfile'
  require 'fileutils'
  require 'puppet/util'

  desc 'Rsync provider'

  confine :kernel => 'Linux'
  commands :rsync => 'rsync'

  def initialize(*args)
    super(*args)

    # This will be used to temporarily house the password file
    @passfile = Tempfile.new('.rsync_provider')
  end

  def action
    @resource[:action]
  end

  # Unfortunately, all of the work is done here since an rsync check is a very
  # heavyweight operation.
  #
  # We've chosen to sync here because of the potential overhead involved with a
  # double rsync run.
  def action_insync?
    cmd = build_command.join(' ')
    debug %(Executing command #{cmd} with password #{get_password})
    output = Puppet::Util::Execution.execute(cmd, :failonfail => false, :combine => true)

    # We're done with the password file here...
    @passfile.close

    is_insync = true
    if output.exitstatus != 0

      selinux_failure = false

      if @resource[:logoutput] != :false
        output.each_line do |line|
          if ( Facter[:selinux_current_mode] != 'disabled' ) &&
             line =~ /attr\(.*security.selinux/
          then
            selinux_failure = true
          end
          if selinux_failure && @resource[:ignore_selinux] == :true
            self.send(:debug, line.chomp)
          else
            self.send(@resource[:loglevel], line.chomp)
          end
        end
      end

      unless (selinux_failure && @resource[:ignore_selinux] == :true)
        self.fail %(Rsync exited with code #{status.to_s})
      end

    elsif output !~ /^\s*$/
      if @resource[:logoutput] != false &&
         @resource[:logoutput] != :false &&
         @resource[:logoutput] != :on_failure
      then
        output.each_line do |line|
          self.send(@resource[:loglevel], line.chomp)
        end
      end
      is_insync = false
    end
    is_insync
  end

  def action=(should)
    debug 'syncing...'
  end

  private

  def get_source
    source = ''
    if @resource[:source]
      resource_source = @resource[:source]
    else
      resource_source = @resource[:source_path]
    end

    if @resource[:protocol]
      resource_protocol = @resource[:protocol]
    else
      resource_protocol = @resource[:proto]
    end

    if @resource[:server]
      resource_server = @resource[:server]
    else
      resource_server = @resource[:rsync_server]
    end

    if (
        @resource[:server] ||
        @resource[:rsync_server]
      ) && (
        @resource[:action] == :pull ||
        @resource[:action].eql?('pull')
    )
    then
      source << resource_protocol
      source << '://'
      if @resource[:user]
        source << %(#{@resource[:user]}@)
      end
      source << resource_server
      source << '/' unless resource_source =~ /^\//
      source << resource_source
    else
      source << resource_source
    end
    source
  end

  def get_target
    target = ''
    if @resource[:target]
      resource_target = @resource[:target]
    else
      resource_target = @resource[:target_path]
    end
    if @resource[:protocol]
      resource_protocol = @resource[:protocol]
    else
      resource_protocol = @resource[:proto]
    end
    if @resource[:server]
      resource_server = @resource[:server]
    else
      resource_server = @resource[:rsync_server]
    end

    if (
        @resource[:server] ||
        @resource[:rsync_server]
      ) && (
        @resource[:action] == :push ||
        @resource[:action].eql?('push')
    )
    then
      target << resource_protocol
      target << '://'
      if @resource[:user]
        target << %(#{@resource[:user]}@)
      end
      target << resource_server
      target << '/' unless resource_target =~ /^\//
      target << resource_target
    else
      target << resource_target
    end
  end

  def get_flags
    flags = []
    flags << '-A' if @resource.preserve_acl?
    flags << '-X' if @resource.preserve_xattrs?
    flags << '-o' if @resource.preserve_owner?
    flags << '-g' if @resource.preserve_group?
    flags << '--delete' if @resource.delete?
    flags << '-D' if @resource.preserve_devices?
    flags << '--no-implied-dirs' if @resource.no_implied_dirs?
    flags << '-z' if @resource.compress?
    flags << '-r' if @resource.recurse?
    flags << '-H' if @resource.hard_links?
    if @resource.copy_links?
      flags << '-L'
    else
      flags << '-l'
    end
    if @resource.size_only?
      flags << '--size-only'
    else
      flags << '-c'
    end
  end

  def get_timeout
    if @resource[:timeout]
      timeout = @resource[:timeout].to_s
    elsif @resource[:rsync_timeout]
      timeout = @resource[:rsync_timeout].to_s
    else
      timeout = @resource[:contimeout]
    end

    timeout and timeout = %(--contimeout=#{timeout})

    timeout
  end

  def get_iotimeout
    if @resource[:iotimeout]
      io_timeout = %(--timeout=#{@resource[:iotimeout]})
    end

    io_timeout
  end

  def get_exclude
    exclude = []
    if @resource[:exclude]
      @resource[:exclude].each do |val|
        exclude << %(--exclude='#{val}')
      end
    end
    exclude
  end

  def get_bwlimit
    bwlimit = ''
    if @resource[:bwlimit]
      bwlimit << %(--bwlimit=#{@resource[:bwlimit].to_s})
    end
    bwlimit
  end

  def get_password
    password = @resource[:password]
    password = @resource[:pass] unless password

    # We *always* set a password so that we don't hang at a prompt!
    if !password || ( password =~ /^(\s*)$/ )
      password = '__*invalid_password_provided*__'
    end

    password
  end

  def get_password_file
    @passfile.puts(get_password)
    @passfile.flush

    return %(--password-file=#{@passfile.path})
  end

  def build_command
    cmd = []
    if @resource[:path]
      cmd << @resource[:path]
    else
      cmd << command('rsync')
    end
    cmd << ['-i', '-p', '-S']
    cmd << ['--dry-run'] if Puppet[:noop]
    cmd << get_flags
    cmd << get_exclude
    cmd << get_bwlimit
    cmd << get_timeout
    cmd << get_iotimeout
    cmd << get_password_file
    cmd << get_source
    cmd << get_target
    cmd.flatten!
    cmd = cmd.reject{ |x| x =~ /^\s*$/ }
    cmd
  end

end
