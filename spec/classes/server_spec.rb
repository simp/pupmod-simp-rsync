require 'spec_helper'

describe 'rsync::server' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context "on #{os}" do
        it { is_expected.to create_class('rsync') }
        it { is_expected.to create_class('stunnel') }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat_build('rsync').with_target('/etc/rsyncd.conf') }
        it { is_expected.to create_file('/etc/rsyncd.conf').that_subscribes_to('Concat_build[rsync]') }
        it { is_expected.to create_file('/etc/init.d/rsync').with_source('puppet:///modules/rsync/rsync.init') }
        it { is_expected.to create_service('rsync').that_subscribes_to('Service[stunnel]') }

        context 'no_stunnel' do
          let(:params){{ :use_stunnel => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_concat_build('rsync').with_target('/etc/rsyncd.conf') }
          it { is_expected.to create_file('/etc/rsyncd.conf').that_subscribes_to('Concat_build[rsync]') }
          it { is_expected.to create_file('/etc/init.d/rsync').with_source('puppet:///modules/rsync/rsync.init') }
          it { is_expected.to create_service('rsync') }
          it { is_expected.to create_service('rsync').without_subscribes }
        end
      end
    end
  end
end
