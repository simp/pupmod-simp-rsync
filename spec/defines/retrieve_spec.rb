require 'spec_helper'

describe 'rsync::retrieve' do
  let(:facts) {{
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :selinux_current_mode => 'permissive'
  }}

  let(:title){ 'test' }
  let(:params){{
    :source_path => 'foo/bar',
    :target_path => '/foo/bar',
    :rsync_server => 'rsync.bar.baz'
  }}

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_rsync(title) }
end
