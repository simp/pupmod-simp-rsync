require 'spec_helper'

describe 'rsync::server' do
  let(:facts) {{
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :selinux_current_mode => 'permissive',
    :operatingsystem => 'RedHat',
    :grub_version => '2.0',
    :uid_min => '500',
    :operatingsystemmajrelease => '7'
  }}

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
