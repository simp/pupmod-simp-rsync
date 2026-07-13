require 'spec_helper_acceptance'

test_name 'rsync class'

describe 'rsync class' do
  let(:manifest) do
    <<~EOS
      include 'rsync::server'

      include 'iptables'

      iptables::listen::tcp_stateful { 'ssh':
        dports       => 22,
        trusted_nets => ['any'],
      }

      file { '/srv/rsync':
        ensure => 'directory',
      }

      file { '/srv/rsync/test':
        ensure => 'directory',
      }

      file { '/srv/rsync/test/test_file':
        ensure  => 'file',
        content => 'What a Test File',
      }

      rsync::server::section { 'test':
        auth_users => ['test_user'],
        comment    => 'A test system',
        path       => '/srv/rsync/test',
        require    => File['/srv/rsync/test/test_file'],
      }

      rsync::retrieve { 'test_pull':
        user         => 'test_user',
        pass         => simplib::passgen('test_user'),
        source_path  => 'test/test_file',
        target_path  => '/tmp',
        rsync_server => '127.0.0.1',
        require      => Rsync::Server::Section['test'],
      }
    EOS
  end

  let(:hieradata) do
    {
      'iptables::precise_match' => true,
      'simp_options::pki'       => false,
      'rsync::server::stunnel'  => false,
    }
  end

  hosts.each do |host|
    # Exercise noop from a clean (uninstalled) state: on a fresh node the Sicura
    # console previews the module with `puppet apply --noop`, which must not error
    # even though nothing rsync manages exists yet. Real idempotence is covered
    # by the applies below. A post-convergence noop check is deliberately omitted:
    # `puppet apply --noop --detailed-exitcodes` always exits 0, so it could never
    # fail and would test nothing.
    context 'in noop mode from a clean state' do
      # Setup, not an assertion: as before(:context) a failure errors this context
      # rather than aborting the whole suite under .rspec's --fail-fast. `puppet
      # resource` exits 0 whether it removes the package or finds it already absent
      # (no --detailed-exitcodes), so no acceptable_exit_codes override is needed.
      before(:context) do
        on(host, 'puppet resource package rsync ensure=absent')
      end

      it 'applies without errors in noop mode' do
        apply_manifest_on(host, manifest, catch_failures: true, noop: true)
      end

      # Proof noop engaged nothing: the acceptance nodeset is EL, so rpm -q exits 1
      # when rsync is absent; beaker raises on any other exit code.
      it 'does not install the rsync package' do
        on(host, 'rpm -q rsync', acceptable_exit_codes: [1])
      end
    end

    it 'works with no errors' do
      set_hieradata_on(host, hieradata)
      apply_manifest_on(host, manifest, catch_failures: true)
    end

    it 'is idempotent' do
      # FIXME: - Workaround for systemd::dropin_file idempotency issue:
      #   Selinux type of the override unit file (from simp-rsyslog module)
      #   gets fixed with a second puppet run.
      apply_manifest_on(host, manifest, catch_failures: true)

      apply_manifest_on(host, manifest, { catch_changes: true })
    end

    it 'has a file transferred' do
      on(host, 'ls /tmp/test_file', acceptable_exit_codes: [0])
    end
  end
end
