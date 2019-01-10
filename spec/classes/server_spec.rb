require 'spec_helper'

describe 'rsync::server' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to create_class('rsync') }
        it { is_expected.to create_class('stunnel') }
        it { is_expected.to create_concat('/etc/rsyncd.conf').that_notifies('Service[rsyncd]') }
        it { is_expected.to create_service('rsyncd').that_subscribes_to('Service[stunnel]') }
        it { is_expected.to create_concat__fragment('rsync_global').with_content(/address = 127.0.0.1/) }
        it { is_expected.to_not create_tcpwrappers__allow('rsync') }

        context 'no_stunnel' do
          let(:params){{ :stunnel => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_concat('/etc/rsyncd.conf').that_notifies('Service[rsyncd]') }
          it { is_expected.to create_service('rsyncd') }
          it { is_expected.to create_service('rsyncd').without_subscribes }
          it { is_expected.to create_concat__fragment('rsync_global').with_content(/address = 0.0.0.0/) }
          it { is_expected.to_not create_tcpwrappers__allow('rsync') }
        end

        context 'with tcpwrappers' do
          let(:params) {{
            :tcpwrappers => true
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_concat('/etc/rsyncd.conf').that_notifies('Service[rsyncd]') }
          it { is_expected.to create_service('rsyncd') }
          it { is_expected.to create_service('rsyncd').without_subscribes }
          it { is_expected.to create_concat__fragment('rsync_global').with_content(/address = 127.0.0.1/) }
          it { is_expected.to create_tcpwrappers__allow('rsync_server') }
        end

        context 'with tcpwrappers and no_stunnel' do
          let(:params) {{
            :stunnel     => false,
            :tcpwrappers => true,
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_concat('/etc/rsyncd.conf').that_notifies('Service[rsyncd]') }
          it { is_expected.to create_service('rsyncd') }
          it { is_expected.to create_service('rsyncd').without_subscribes }
          it { is_expected.to create_concat__fragment('rsync_global').with_content(/address = 0.0.0.0/) }
          it { is_expected.to create_tcpwrappers__allow('rsync') }
        end
      end
    end
  end
end
