require 'spec_helper'

describe 'rsync' do
  let(:facts) {{
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :selinux_current_mode => 'permissive'
  }}

  it { should create_class('rsync') }

  context 'base' do
    it { should compile.with_all_deps }
    it { should create_selboolean('rsync_client') }
    it { should create_selboolean('rsync_export_all_ro') }
  end

  context 'no_selinux' do
    let(:facts) {{ :selinux_current_mode => 'disabled' }}

    it { should compile.with_all_deps }
    it { should_not create_selboolean('rsync_client') }
    it { should_not create_selboolean('rsync_export_all_ro') }
  end
end
