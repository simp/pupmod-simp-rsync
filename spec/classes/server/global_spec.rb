require 'spec_helper'

describe 'rsync::server::global' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat_fragment('rsync+global').with_content(/address = 127.0.0.1/) }
        it { is_expected.to create_tcpwrappers__allow('rsync') }
      end
    end
  end
end
