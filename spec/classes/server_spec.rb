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

  it { should create_class('rsync') }
  it { should create_class('stunnel') }

  it { should compile.with_all_deps }
  it { should create_concat_build('rsync').with_target('/etc/rsyncd.conf') }
  it { should create_file('/etc/rsyncd.conf').that_subscribes_to('Concat_build[rsync]') }
  it { should create_file('/etc/init.d/rsync').with_source('puppet:///modules/rsync/rsync.init') }
  it { should create_service('rsync').that_subscribes_to('Service[stunnel]') }

  context 'no_stunnel' do
    let(:params){{ :use_stunnel => false }}

    it { should compile.with_all_deps }
    it { should create_concat_build('rsync').with_target('/etc/rsyncd.conf') }
    it { should create_file('/etc/rsyncd.conf').that_subscribes_to('Concat_build[rsync]') }
    it { should create_file('/etc/init.d/rsync').with_source('puppet:///modules/rsync/rsync.init') }
    it { should create_service('rsync') }
    it { should create_service('rsync').without_subscribes }
  end
end
