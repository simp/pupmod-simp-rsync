require 'spec_helper'

describe 'rsync::server::section' do
  def mock_selinux_enforcing_facts(os_facts)
    os_facts[:selinux] = true
    os_facts[:os][:selinux][:config_mode] = 'enforcing'
    os_facts[:os][:selinux][:config_policy] = 'targeted'
    os_facts[:os][:selinux][:current_mode] = 'enforcing'
    os_facts[:os][:selinux][:enabled] = true
    os_facts[:os][:selinux][:enforced] = true
    os_facts
  end
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'test' }

      let(:facts) do
        os_facts = os_facts.dup
        os_facts = mock_selinux_enforcing_facts(os_facts)
        os_facts
      end

      let(:pre_condition) do
        'include "rsync::server"'
      end

      context 'with default parameters' do
        let(:params) do
          {
            path: '/test/dir',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat__fragment("rsync_#{title}.section") }
        it { is_expected.not_to create_file("/etc/rsync/#{title}.rsyncd.secrets") }
      end

      context 'with user_pass and comment parameters set' do
        let(:params) do
          {
            path: '/test/dir',
            user_pass: [ 'user1:user1password', 'user2:user2password', 'skipme'],
            comment: 'section TEST',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets").with(
            ensure: 'file',
            owner: 'root',
            group: 'root',
            mode: '0600',
            show_diff: false,
            content: <<~EOM,
              user1:user1password
              user2:user2password
            EOM
          )
        end
      end

      context 'with auth_users parameter set' do
        let(:params) do
          {
            path: '/test/dir',
            auth_users: [ 'authuser1', 'authuser2'],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets").with_content(%r{^authuser1:}) }
        it { is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets").with_content(%r{^authuser2:}) }
      end
    end
  end
end
