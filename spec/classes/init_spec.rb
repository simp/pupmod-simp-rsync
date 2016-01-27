require 'spec_helper'

describe 'rsync' do
  let(:facts) {{
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :selinux_current_mode => 'permissive'
  }}

  it { is_expected.to create_class('rsync') }

  context 'base' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_selboolean('rsync_client') }
    it { is_expected.to create_selboolean('rsync_export_all_ro') }
  end

  context 'no_selinux' do
    let(:facts) {{ :selinux_current_mode => 'disabled' }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to create_selboolean('rsync_client') }
    it { is_expected.not_to create_selboolean('rsync_export_all_ro') }
  end
end
