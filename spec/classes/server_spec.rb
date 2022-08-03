require 'spec_helper'

describe 'rsync::server' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }
      let(:params) { { tcpwrappers: false } }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to create_class('rsync') }
        it { is_expected.to create_class('stunnel') }
        it { is_expected.to create_stunnel__connection('rsync_server').that_notifies('Service[rsyncd]') }
        it { is_expected.to create_concat('/etc/rsyncd.conf').that_notifies('Service[rsyncd]') }
        it { is_expected.to create_service('rsyncd').that_subscribes_to('Stunnel::Connection[rsync_server]') }
        it { is_expected.to_not create_tcpwrappers__allow('rsync_server') }
        context 'with tcpwrappers' do
          let(:params) { super().merge(tcpwrappers: true) }

          it { is_expected.to create_tcpwrappers__allow('rsync_server') }
        end

        context 'no_stunnel' do
          let(:params) { super().merge(stunnel: false) }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_concat('/etc/rsyncd.conf').that_notifies('Service[rsyncd]') }
          it { is_expected.to create_service('rsyncd') }
          it { is_expected.to create_service('rsyncd').without_subscribes }
          it { is_expected.to_not create_class('stunnel') }
          it { is_expected.to_not create_tcpwrappers__allow('rsync') }
          context 'with tcpwrappers' do
            let(:params) { super().merge(tcpwrappers: true) }

            it { is_expected.to create_tcpwrappers__allow('rsync') }
          end
        end
      end
    end
  end
end
