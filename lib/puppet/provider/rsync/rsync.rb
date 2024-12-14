Puppet::Type.type(:rsync).provide(:rsync) do
  require 'tempfile'
  require 'fileutils'
  require 'puppet/util'

  desc 'Rsync provider'

  confine kernel: 'Linux'
  commands rsync: 'rsync'

  def initialize(*args)
    super
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
    # This will be used to temporarily house the password file
    @passfile = Tempfile.new('.rsync_provider')

    cmd = build_command.join(' ')
    debug %(Executing command #{cmd} with password #{get_password})
    output = Puppet::Util::Execution.execute(cmd, failonfail: false, combine: true)

    # We're done with the password file here...
    @passfile.close

    is_insync = true
    if output.exitstatus != 0

      selinux_failure = false

      if @resource[:logoutput] != :false
        output.each_line do |line|
          if (Facter[:selinux_current_mode] != 'disabled') &&
             line =~ %r{attr\(.*security.selinux}
            selinux_failure = true
          end
          if selinux_failure && @resource[:ignore_selinux] == :true
            send(:debug, line.chomp)
          else
            send(@resource[:loglevel], line.chomp)
          end
        end
      end

      unless selinux_failure && @resource[:ignore_selinux] == :true
        self.fail %(Rsync exited with code #{output.exitstatus}\n)
      end

    elsif !%r{^\s*$}.match?(output)
      if @resource[:logoutput] != false &&
         @resource[:logoutput] != :false &&
         @resource[:logoutput] != :on_failure
        output.each_line do |line|
          send(@resource[:loglevel], line.chomp)
        end
      end
      is_insync = false
    end
    is_insync
  end

  def action=(_should)
    debug 'syncing...'
  end

  private

  def get_source
    source = ''
    resource_source = if @resource[:source]
                        @resource[:source]
                      else
                        @resource[:source_path]
                      end

    resource_protocol = if @resource[:protocol]
                          @resource[:protocol]
                        else
                          @resource[:proto]
                        end

    resource_server = if @resource[:server]
                        @resource[:server]
                      else
                        @resource[:rsync_server]
                      end

    if (
        @resource[:server] ||
        @resource[:rsync_server]
      ) && (
        @resource[:action] == :pull ||
        @resource[:action].eql?('pull')
      )
      source << resource_protocol
      source << '://'
      if @resource[:user]
        source << %(#{@resource[:user]}@)
      end
      source << resource_server
      source << '/' unless %r{^/}.match?(resource_source)
    end
    source << resource_source
    source
  end

  def get_target
    target = ''
    resource_target = if @resource[:target]
                        @resource[:target]
                      else
                        @resource[:target_path]
                      end
    resource_protocol = if @resource[:protocol]
                          @resource[:protocol]
                        else
                          @resource[:proto]
                        end
    resource_server = if @resource[:server]
                        @resource[:server]
                      else
                        @resource[:rsync_server]
                      end

    if (
        @resource[:server] ||
        @resource[:rsync_server]
      ) && (
        @resource[:action] == :push ||
        @resource[:action].eql?('push')
      )
      target << resource_protocol
      target << '://'
      if @resource[:user]
        target << %(#{@resource[:user]}@)
      end
      target << resource_server
      target << '/' unless %r{^/}.match?(resource_target)
    end
    target << resource_target
  end

  def get_flags
    flags = []
    flags << '-p' if @resource.preserve_perms?
    flags << '--chmod=u=rwX,g=rX,o-rwx' unless @resource.preserve_perms?
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
    flags << if @resource.copy_links?
               '-L'
             else
               '-l'
             end
    flags << if @resource.size_only?
               '--size-only'
             else
               '-c'
             end
  end

  def get_timeout
    timeout = if @resource[:timeout]
                @resource[:timeout].to_s
              elsif @resource[:rsync_timeout]
                @resource[:rsync_timeout].to_s
              else
                @resource[:contimeout]
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
    @resource[:exclude]&.each do |val|
      exclude << %(--exclude='#{val}')
    end
    exclude
  end

  def get_bwlimit
    bwlimit = ''
    if @resource[:bwlimit]
      bwlimit << %(--bwlimit=#{@resource[:bwlimit]})
    end
    bwlimit
  end

  def get_password
    password = @resource[:password]
    password = @resource[:pass] unless password

    # We *always* set a password so that we don't hang at a prompt!
    if !password || (password =~ %r{^(\s*)$})
      password = '__*invalid_password_provided*__'
    end

    password
  end

  def get_password_file
    @passfile.puts(get_password)
    @passfile.flush

    %(--password-file=#{@passfile.path})
  end

  def build_command
    cmd = []
    cmd << if @resource[:path]
             @resource[:path]
           else
             command('rsync')
           end
    cmd << ['-i', '-S']
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
    cmd = cmd.reject { |x| x =~ %r{^\s*$} }
    cmd
  end
end
