require 'spec_helper_acceptance'

test_name 'server and client stunnel connectivity'

describe 'server and client stunnel connectivity' do
  if hosts.count < 2
    it 'only runs with more than one host' do
      skip('You need at least two hosts in your nodeset to run this test')
    end
  else
    index_pairs = unique_host_pairs(hosts)
    index_pairs.each do |index1, index2|
      # Test interoperability between a pair of hosts in the node set, each
      # acting as a rsync server to the other.
      server1 = hosts[index1]
      server2 = hosts[index2]
      context "Interoperability between #{server1} and #{server2}" do
        # rubocop:disable RSpec/IndexedLet
        let(:file_content1) do
          "What a Test File for #{server1} and #{server2} testing"
        end

        let(:file_content2) do
          "What a Test File for #{server2} and #{server1} testing"
        end

        let(:manifest_server1) do
          <<-EOS
            include 'rsync::server'

            include 'iptables'

            iptables::listen::tcp_stateful { 'ssh':
              dports       => 22,
              trusted_nets => ['any']
            }

            file { '/srv/rsync':
              ensure => 'directory'
            }

            file { '/srv/rsync/test':
              ensure => 'directory'
            }

            file { '/srv/rsync/test/test_file_srvcli2_server1':
              ensure  => 'file',
              content => '#{file_content1}'
            }

            rsync::server::section { 'test':
              auth_users  => ['test_user'],
              user_pass   => ['test_user:test_pass'],
              comment     => 'A test system',
              path        => '/srv/rsync/test',
              require     => File['/srv/rsync/test/test_file_srvcli2_server1']
            }

            stunnel::connection { 'rsync':
              connect => ["#{server2_fqdn}:8730"],
              accept  => '127.0.0.1:8873'
            }
          EOS
        end

        let(:manifest_server2) do
          <<-EOS
            include 'rsync::server'

            include 'iptables'

            iptables::listen::tcp_stateful { 'ssh':
              dports       => 22,
              trusted_nets => ['any']
            }

            file { '/srv/rsync':
              ensure => 'directory'
            }

            file { '/srv/rsync/test':
              ensure => 'directory'
            }

            file { '/srv/rsync/test/test_file_srvcli2_server2':
              ensure  => 'file',
              content => '#{file_content2}'
            }

            rsync::server::section { 'test':
              auth_users  => ['test_user'],
              user_pass   => ['test_user:test_pass'],
              comment     => 'A test system',
              path        => '/srv/rsync/test',
              require     => File['/srv/rsync/test/test_file_srvcli2_server2']
            }

            stunnel::connection { 'rsync':
              connect => ["#{server1_fqdn}:8730"],
              accept  => '127.0.0.1:873'
            }
          EOS
        end

        let(:manifest_test_server1) do
          <<-EOS
            rsync::retrieve { 'test_pull':
              user         => 'test_user',
              pass         => 'test_pass',
              source_path  => 'test/test_file_srvcli2_server1',
              target_path  => '/tmp',
              rsync_server => '127.0.0.1',
            }
          EOS
        end

        let(:manifest_test_server2) do
          <<-EOS
            rsync::retrieve { 'test_pull':
              user         => 'test_user',
              pass         => 'test_pass',
              source_path  => 'test/test_file_srvcli2_server2',
              target_path  => '/tmp',
              rsync_server => '127.0.0.1:8873',
            }
          EOS
        end

        let(:hieradata_server1) do
          {
            'iptables::precise_match'     => true,
         'simp_options::pki'           => true,
         'simp_options::pki::source'   => '/etc/pki/simp-testing/pki',
         'simp_options::firewall'      => true,
         'rsync::server::stunnel'      => true,
         'rsync::server::trusted_nets' => [server2_ip],
          }
        end

        let(:hieradata_server2) do
          {
            'iptables::precise_match'     => true,
         'simp_options::pki'           => true,
         'simp_options::pki::source'   => '/etc/pki/simp-testing/pki',
         'simp_options::firewall'      => true,
         'rsync::server::stunnel'      => true,
         'rsync::server::global::port' => 8873,
         'rsync::server::trusted_nets' => [server1_ip],
          }
        end

        let(:server1_interface) { get_private_network_interface(server1) }
        let(:server1_ip) { fact_on(server1, %(ipaddress_#{server1_interface})) }
        let(:server1_fqdn) { fact_on(server1, 'fqdn') }
        let(:server2_interface) { get_private_network_interface(server2) }
        let(:server2_ip) { fact_on(server2, %(ipaddress_#{server2_interface})) }
        let(:server2_fqdn) { fact_on(server2, 'fqdn') }
        # rubocop:enable RSpec/IndexedLet

        context 'setup server and client hosts' do
          context "on #{server1}" do
            it 'sets hieradata' do
              set_hieradata_on(server1, hieradata_server1)
            end

            it 'works with no errors' do
              apply_manifest_on(server1, manifest_server1, catch_failures: true)
            end

            it 'is idempotent' do
              apply_manifest_on(server1, manifest_server1, catch_changes: true)
            end
          end

          context "on #{server2}" do
            it 'sets hieradata' do
              set_hieradata_on(server2, hieradata_server2)
            end

            it 'works with no errors' do
              apply_manifest_on(server2, manifest_server2, catch_failures: true)
            end

            it 'is idempotent' do
              apply_manifest_on(server2, manifest_server2, catch_changes: true)
            end
          end
        end

        context 'test a file retrieval' do
          # rubocop:disable RSpec/RepeatedDescription
          [server1, server2].each do |host|
            it 'starts with a clean state' do
              on(host, 'rm -rf  /tmp/test_file_srvcli*')
            end

            it "runs server1 retrieval code on #{host}" do
              apply_manifest_on(host, manifest_test_server1, catch_failures: true)
            end

            it 'has a file transferred' do
              on(host, 'ls /tmp/test_file_srvcli2_server1', acceptable_exit_codes: [0])
              result = on(host, 'cat /tmp/test_file_srvcli2_server1').stdout
              expect(result).to match(%r{#{Regexp.escape(file_content1)}})
            end

            it "runs server2 retrieval code on #{host}" do
              apply_manifest_on(host, manifest_test_server2, catch_failures: true)
            end

            it 'has a file transferred' do
              on(host, 'ls /tmp/test_file_srvcli2_server2', acceptable_exit_codes: [0])
              result = on(host, 'cat /tmp/test_file_srvcli2_server2').stdout
              expect(result).to match(%r{#{Regexp.escape(file_content2)}})
            end
          end
          # rubocop:enable RSpec/RepeatedDescription
        end
      end
    end
  end
end
