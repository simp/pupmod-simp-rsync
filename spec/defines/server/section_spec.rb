require 'spec_helper'

describe 'rsync::server::section' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:title) { 'test' }

      let(:facts) { os_facts }

      let(:pre_condition) {
        'include "::rsync::server"'
      }

      let(:params) {{
        :path => '/test/dir'
      }}

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat__fragment("rsync_#{title}.section") }
      end
    end
  end
end
