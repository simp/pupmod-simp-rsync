require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
require_relative 'acceptance/helpers/utils'

include Simp::BeakerHelpers
include Acceptance::Helpers::Utils

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end

RSpec.configure do |c|
  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Detect cases in which no examples are executed (e.g., nodeset does not
  # have hosts with required roles)
  c.fail_if_no_examples = true

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install modules and dependencies from spec/fixtures/modules
    copy_fixture_modules_to(hosts)
    begin
      server = only_host_with_role(hosts, 'server')
    rescue ArgumentError => e
      server = only_host_with_role(hosts, 'default')
    end

    # Generate and install PKI certificates on each SUT
    Dir.mktmpdir do |cert_dir|
      run_fake_pki_ca_on(server, hosts, cert_dir)
      hosts.each { |sut| copy_pki_to(sut, cert_dir, '/etc/pki/simp-testing') }
    end

    # add PKI keys
    copy_keydist_to(server)
  rescue StandardError, ScriptError => e
    raise e unless ENV['PRY']
    require 'pry'
    binding.pry
  end
end

def get_private_network_interface(host)
  interfaces = fact_on(host, 'interfaces').split(',')

  # remove interfaces we know are not the private network interface
  interfaces.delete_if do |ifc|
    ifc == 'lo' or
      ifc.include?('ip_') or # IPsec tunnel
      ifc == 'enp0s3' or     # public interface for puppetlabs/centos-7.2-64-nocm virtual box
      ifc == 'eth0'          # public interface for centos/7 virtual box
  end
  raise("Could not determine the interface for the #{host}'s private network") unless interfaces.size == 1
  interfaces[0]
end
