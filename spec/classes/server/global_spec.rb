require 'spec_helper'

describe 'rsync::server::global' do
  let(:facts) {{
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :selinux_current_mode => 'permissive',
    :interfaces => 'eth0'
  }}

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_concat_fragment('rsync+global').with_content(/address = 127.0.0.1/) }
  it { is_expected.to create_tcpwrappers__allow('rsync') }
end
