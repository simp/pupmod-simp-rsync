require 'spec_helper'

describe 'rsync::server::global' do
  before(:each) do
    # Mask 'assert_private' for testing
    Puppet::Parser::Functions.newfunction(:assert_private, type: :rvalue) { |args| }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat__fragment('rsync_global').with_content(%r{address = 127.0.0.1}) }
        it { is_expected.not_to create_tcpwrappers__allow('rsync') }

        context 'with tcpwrappers' do
          let(:params) do
            {
              tcpwrappers: true
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_concat__fragment('rsync_global').with_content(%r{address = 127.0.0.1}) }
          it { is_expected.to create_tcpwrappers__allow('rsync_server') }
        end
      end
    end
  end
end
