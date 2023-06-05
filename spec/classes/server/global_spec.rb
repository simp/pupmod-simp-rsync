require 'spec_helper'

describe 'rsync::server::global' do
  before(:each) do
    Puppet::Parser::Functions.newfunction('assert_private') do |f|
      f.stubs(:call).returns(true)
    end
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }
      let(:params) { { 'port' => 873 } }

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_concat__fragment('rsync_global').with_content(/address = 127.0.0.1/) }
      end
    end
  end
end
