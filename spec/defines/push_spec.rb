require 'spec_helper'

describe 'rsync::push' do
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

  # We can't do this right now because the test loader seems to be
  # parse order dependent for defines that call other defines.
  #it { should compile.with_all_deps }
  it { is_expected.to create_rsync__retrieve("pull_#{title}") }
end
