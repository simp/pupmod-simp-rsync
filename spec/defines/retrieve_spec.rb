require 'spec_helper'

describe 'rsync::retrieve' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      let(:pre_condition) do
        'include "::rsync::server"'
      end

      context "on #{os}" do
        let(:title) { 'test' }

        let(:params) do
          {
            source_path: 'foo/bar',
         target_path: '/foo/bar',
         rsync_server: 'rsync.bar.baz'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_rsync(title) }
      end
    end
  end
end
