require 'spec_helper'

describe 'rsync' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context "on #{os}" do
        it { is_expected.to create_class('rsync') }

        context 'base' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('rsync::selinux') }
          it { is_expected.to create_selboolean('rsync_client') }
          it { is_expected.to create_selboolean('rsync_export_all_ro') }
        end

        context 'no_selinux' do
          let(:facts) {os_facts.merge({ :selinux_current_mode => 'disabled' })}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not create_class('rsync::selinux') }
        end
      end
    end
  end
end
