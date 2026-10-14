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

      let(:fragment) { "rsync_#{title}.section" }
      let(:secrets) { "/etc/rsync/#{title}.rsyncd.secrets" }

      context 'with default parameters' do
        let(:params) do
          {
            path: '/test/dir',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat__fragment(fragment).without_content(%r{^auth users}) }
        it { is_expected.to create_concat__fragment(fragment).without_content(%r{^secrets file}) }
        it { is_expected.not_to create_file(secrets) }
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
        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^auth users = \*$}) }
        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^secrets file = #{secrets}$}) }
        it do
          is_expected.to create_file(secrets).with(
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
        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^auth users = authuser1,authuser2$}) }
        it { is_expected.to create_file(secrets).with_content(%r{^authuser1:}) }
        it { is_expected.to create_file(secrets).with_content(%r{^authuser2:}) }
      end

      context 'with both auth_users and user_pass set' do
        let(:params) do
          {
            path: '/test/dir',
            auth_users: ['user1'],
            user_pass: ['user1:user1password', 'user2:user2password'],
          }
        end

        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^auth users = user1$}) }
        it { is_expected.to create_file(secrets).with_content("user1:user1password\nuser2:user2password\n") }
      end

      context 'with an empty auth_users' do
        let(:params) { { path: '/test/dir', auth_users: [] } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^auth users = \*:deny$}) }
        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^secrets file = #{secrets}$}) }
        it { is_expected.to create_file(secrets) }
      end

      [
        [],
        ['skipme'],
      ].each do |user_pass|
        context "with user_pass set to #{user_pass}" do
          let(:params) { { path: '/test/dir', user_pass: user_pass } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_concat__fragment(fragment).with_content(%r{^auth users = \*$}) }
          it { is_expected.to create_concat__fragment(fragment).with_content(%r{^secrets file = #{secrets}$}) }
          it { is_expected.to create_file(secrets).with_content("\n") }
        end
      end

      context 'with a non-root uid and gid' do
        let(:params) do
          {
            path: '/test/dir',
            auth_users: ['authuser1'],
            uid: 'rsyncuser',
            gid: 'rsyncgroup',
          }
        end

        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^uid = rsyncuser$}) }
        it { is_expected.to create_concat__fragment(fragment).with_content(%r{^gid = rsyncgroup$}) }
        it { is_expected.to create_file(secrets).with(owner: 'root', group: 'root', mode: '0600') }
      end
    end
  end
end
