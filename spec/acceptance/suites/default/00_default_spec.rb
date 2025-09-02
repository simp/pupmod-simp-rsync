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
