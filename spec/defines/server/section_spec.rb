require 'spec_helper'

describe 'rsync::server::section' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'test' }
      let(:facts) { os_facts }

      context 'with default parameters' do
        let(:params) {{
          :path => '/test/dir'
        }}

        it 'renders the section as an anonymous share, with no secrets file' do
          is_expected.to compile.with_all_deps
          is_expected.to create_concat__fragment("rsync_#{title}.section")
          is_expected.to_not create_concat__fragment("rsync_#{title}.section")
            .with_content(%r{auth users = })
            .with_content(%r{secrets file = })
          is_expected.to_not create_file("/etc/rsync/#{title}.rsyncd.secrets")
        end
      end

      context 'with user_pass and comment parameters set and without auth_users' do
        let(:params) {{
          :path       => '/test/dir',
          :user_pass  => [ 'user1:user1password', 'user2:user2password'],
          :comment    => 'section TEST'
        }}

        it 'renders the section as an authenticated share, with a secrets file' do
          is_expected.to compile.with_all_deps 
          is_expected.to create_concat__fragment("rsync_#{title}.section")
            .with_content(%r{path = /test/dir$})
            .with_content(%r{section TEST$})
            .with_content(%r{^auth users = all:deny$})
            .with_content(%r{^secrets file = /etc/rsync/test\.rsyncd\.secrets$})
          is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets")
            .with(
              :ensure    => 'file',
              :owner     => 'root',
              :group     => 'root',
              :mode      => '0600',
              :show_diff => false,
              :content   => <<~EOM
                user1:user1password
                user2:user2password
                EOM
            )
        end

        context 'with a badly formatted user:pass line in the user_pass array,' do
          let(:params) { super().merge(user_pass: [ 'user1:user1password', 'baduserpass', 'user2:user2password']) }
 
          it 'fails with an invalid parameter error' do
            is_expected.to compile.and_raise_error(%r{Evaluation Error:.*parameter 'user_pass'.*expects.*, got 'baduserpass'})
          end
        end
      end

      context 'with auth_users parameter set as an Array,' do
        let(:params) {{
          :path       => '/test/dir',
          :auth_users => [ 'authuser1', 'authuser2' ],
        }}

        it 'renders a secrets file and a section with the given auth users' do
          is_expected.to compile.with_all_deps
          is_expected.to create_concat__fragment("rsync_#{title}.section")
            .with_content(%r{^path = /test/dir$})
            .with_content(%r{^auth users = authuser1,authuser2$})
          is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets")
            .with_content(/^authuser1:.+$/)
            .with_content(/^authuser2:.+$/)
        end

        context 'with uid and gid set to a non-root user/group' do
          let(:params) { super().merge(uid: 'testuser', gid: 'testgroup') }

          it 'creates a secrets file owned by root with mode 0600, and sets the given user/group for the section' do
            is_expected.to create_concat__fragment("rsync_#{title}.section")
              .with_content(%r{^uid = testuser$})
              .with_content(%r{^gid = testgroup$})
            is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets")
              .with_owner('root')
              .with_group('root')
              .with_mode('0600')
          end
        end
        context 'with uid and gid set to a non-root user/group' do
          let(:params) { super().merge(auth_users: []) }

          it 'renders a section with a defined secrets file, but not as an anonymous share' do
            is_expected.to create_concat__fragment("rsync_#{title}.section")
              .with_content(%r{^auth users = all:deny$})
            is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets")
              .with_content('')
          end
        end
      end
      context 'with auth_users parameter set as a Hash,' do
        let(:params) {{
          :path       => '/test/dir',
          :auth_users => { 
            'authuser1' => 'pass1', 
            'dontskipme' => '',
            'authuser2' => 'pass2',
          },
        }}

        it 'renders a secrets file and a section with the given auth users' do
          is_expected.to compile.with_all_deps
          is_expected.to create_concat__fragment("rsync_#{title}.section")
            .with_content(%r{^path = /test/dir$})
            .with_content(%r{^auth users = authuser1,dontskipme,authuser2$})
          is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets")
            .with_content(/^authuser1:pass1$/)
            .with_content(/^dontskipme:.+$/)
            .with_content(/^authuser2:pass2$/)
        end

        context 'with uid and gid set to a non-root user/group' do
          let(:params) { super().merge(auth_users: []) }

          it 'renders a section with a defined secrets file, but not as an anonymous share' do
            is_expected.to create_concat__fragment("rsync_#{title}.section")
              .with_content(%r{^auth users = all:deny$})
            is_expected.to create_file("/etc/rsync/#{title}.rsyncd.secrets")
              .with_content('')
          end
        end
      end
    end
  end
end
