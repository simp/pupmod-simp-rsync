require 'spec_helper'

describe 'rsync::server::section' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'test' }

      let(:facts) {
        _facts = os_facts
        _facts[:os] ||= {}
        _facts[:os]['selinux'] ||= {}
        _facts[:os]['selinux']['enabled'] = true

        _facts
      }

      let(:pre_condition) {
        'include "::rsync::server"'
      }

      context 'with default parameters' do
        let(:params) {{
          :path => '/test/dir'
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat__fragment("rsync_#{title}.section") }
        it { is_expected.to_not create_file("/etc/rsync/#{title}.rsyncd.secrets") }
      end

      context 'with user_pass and comment parameters set' do
        let(:params) {{
          :path       => '/test/dir',
          :user_pass  => [ 'user1:user1password', 'user2:user2password', 'skipme'],
          :comment    => 'section TEST'
        }}

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets").with(
            :ensure    => 'file',
            :owner     => 'root',
            :group     => 'root',
            :mode      => '0600',
            :show_diff => false,
            :content   => <<-EOM
user1:user1password
user2:user2password
            EOM
          )
        end
      end

      context 'with auth_users parameter set' do
        let(:params) {{
          :path       => '/test/dir',
          :auth_users => [ 'authuser1', 'authuser2'],
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets").with_content(/^authuser1:/) }
        it { is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets").with_content(/^authuser2:/) }
      end
    end
  end
end
