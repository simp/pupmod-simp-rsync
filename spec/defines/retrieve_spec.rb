require 'spec_helper'

describe 'rsync::retrieve' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      let(:pre_condition) {
        'include "::rsync::server"'
      }

      context "on #{os}" do
        let(:title){ 'test' }

        let(:params){{
          :source_path => 'foo/bar',
          :target_path => '/foo/bar',
          :rsync_server => 'rsync.bar.baz'
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_rsync(title) }
      end
    end
  end
end
