require 'spec_helper'

describe 'rsync' do
  def mock_selinux_disabled_facts(os_facts)
    os_facts[:selinux] = false
    os_facts[:os][:selinux][:config_mode] = 'disabled'
    os_facts[:os][:selinux][:current_mode] = 'disabled'
    os_facts[:os][:selinux][:enabled] = false
    os_facts[:os][:selinux][:enforced] = false
    os_facts
  end

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
          let(:facts) do
            os_facts = os_facts.dup
            os_facts = mock_selinux_disabled_facts(os_facts)
            os_facts
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not create_class('rsync::selinux') }
        end
      end
    end
  end
end
