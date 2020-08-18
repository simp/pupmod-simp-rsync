require 'spec_helper_acceptance'

test_name 'server and client connectivity'

describe 'server and client connectivity' do
  if hosts.count < 2
    it 'only runs with more than one host' do
      skip('You need at least two hosts in your nodeset to run this test')
    end
  else
    index_pairs = unique_host_pairs(hosts)
    index_pairs.each do |index1,index2|
      # Test interoperability between a pair of hosts in the node set, each
      # acting as a rsync server to the other.
      server1 = hosts[index1]
      server2 = hosts[index2]
      context "Interoperability between #{server1} and #{server2}" do

        let(:file_content) {
          "What a Test File for #{server1} and #{server2} testing"
        }

        let(:manifest) {
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

            file { '/srv/rsync/test/test_file_srvcli':
              ensure  => 'file',
              content => '#{file_content}'
            }

            rsync::server::section { 'test':
              auth_users  => ['test_user'],
              user_pass   => ['test_user:test_pass'],
              comment     => 'A test system',
              hosts_allow => ['#{server1_ip}', '#{server2_ip}'],
              path        => '/srv/rsync/test',
              require     => File['/srv/rsync/test/test_file_srvcli']
            }
          EOS
        }

        let(:manifest_test_server1) {
          <<-EOS
            rsync::retrieve { 'test_pull':
              user         => 'test_user',
              pass         => 'test_pass',
              source_path  => 'test/test_file_srvcli',
              target_path  => '/tmp',
              rsync_server => '#{server2_fqdn}:8873',
            }
          EOS
        }

        let(:manifest_test_server2) {
          <<-EOS
            rsync::retrieve { 'test_pull':
              user         => 'test_user',
              pass         => 'test_pass',
              source_path  => 'test/test_file_srvcli',
              target_path  => '/tmp',
              rsync_server => '#{server1_fqdn}',
            }
          EOS
        }

        let(:hieradata_server1) {{
          'iptables::precise_match'             => true,
          'simp_options::pki'                   => false,
          'simp_options::firewall'              => true,
          'rsync::server::stunnel'              => false,
          'rsync::server::trusted_nets'         => [server2_ip],
          'rsync::server::global::trusted_nets' => [server2_ip],
          'rsync::server::global::address'      => '0.0.0.0',
        }}

        let(:hieradata_server2) {{
          'iptables::precise_match'             => true,
          'simp_options::pki'                   => false,
          'simp_options::firewall'              => true,
          'rsync::server::stunnel'              => false,
          'rsync::server::global::port'         => 8873,
          'rsync::server::trusted_nets'         => [server1_ip],
          'rsync::server::global::trusted_nets' => [server1_ip],
          'rsync::server::global::address'      => '0.0.0.0',
        }}

        let(:server1_interface) { get_private_network_interface(server1) }
        let(:server1_ip) { fact_on(server1, %(ipaddress_#{server1_interface})) }
        let(:server1_fqdn) { fact_on(server1, 'fqdn') }
        let(:server2_interface) { get_private_network_interface(server2) }
        let(:server2_ip) { fact_on(server2, %(ipaddress_#{server2_interface})) }
        let(:server2_fqdn) { fact_on(server2, 'fqdn') }

        context 'setup server and client hosts' do
          it "should set hieradata on #{server1}" do
            set_hieradata_on(server1, hieradata_server1)
          end

          it "should set hieradata on #{server2}" do
            set_hieradata_on(server2, hieradata_server2)
          end

          [server1, server2].each do |host|
            context "on #{host}" do
              it 'should work with no errors' do
                apply_manifest_on(host, manifest, :catch_failures => true)
              end

              it 'should be idempotent' do
                # IPTables updates may occur
                apply_manifest_on(host, manifest, :catch_failures => true)
                apply_manifest_on(host, manifest, {:catch_changes => true})
              end
            end
          end
        end

        context 'test a file retrieval' do
          [server1, server2].each do |host|
            it 'should start with a clean state' do
              on(host, 'rm -rf  /tmp/test_file_srvcli')
            end
          end

          it "should run retrieval code on #{server1}" do
            apply_manifest_on(server1, manifest_test_server1, :catch_failures => true)
          end

          it "should run retrieval code on #{server2}" do
            apply_manifest_on(server2, manifest_test_server2, :catch_failures => true)
          end

          [server1, server2].each do |host|
            it 'should have a file transferred' do
              on(host, 'ls /tmp/test_file_srvcli', :acceptable_exit_codes => [0])
              result = on(host, 'cat /tmp/test_file_srvcli').stdout
              expect( result ).to match(/#{Regexp.escape(file_content)}/)
            end
          end
        end
      end
    end
  end
end
