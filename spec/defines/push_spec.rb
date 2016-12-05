require 'spec_helper'

describe 'rsync::push' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      # rsync::retrieve defined type isn't available in this rspec environment
      let(:pre_condition) { <<-EOM
        include "::rsync::server"

        define rsync::retrieve (
            $source_path,
            $target_path,
            $rsync_server = '127.0.0.1',
            $proto = 'rsync',
            $rsync_path = '/usr/bin/rsync',
            $preserve_acl = true,
            $preserve_xattrs = true,
            $preserve_owner = true,
            $preserve_group = true,
            $preserve_devices = false,
            $exclude = ['.svn/','.git/'],
            $rsync_timeout = '2',
            $logoutput = 'on_failure',
            $delete = false,
            $rnotify = undef,
            $bwlimit = '',
            $copy_links = false,
            $size_only = false,
            $no_implied_dirs = true,
            $rsubscribe = undef,
            $user = '',
            $pass = '',
            $pull = true
          ) {
        }
        EOM
      }

      context "on #{os}" do
        let(:title){ 'test' }
        let(:params){{
          :source_path => 'foo/bar',
          :target_path => '/foo/bar',
          :rsync_server => 'rsync.bar.baz'
        }}

        it { should compile.with_all_deps }
        it { is_expected.to create_rsync__retrieve("push_#{title}") }
      end
    end
  end
end
