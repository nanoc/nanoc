# frozen_string_literal: true

describe Nanoc::Checking::Runner, site: true do
  subject(:runner) { described_class.new(site) }

  let(:site) { Nanoc::Core::SiteLoader.new.new_from_cwd }

  describe '#run_specific' do
    it 'can run a predefined check' do
      File.write('output/blah', 'I am stale! Haha!')
      expect { runner.run_specific(%w[stale]) }
        .to output(%r{output/blah:.*stale - file without matching item}m).to_stdout
    end

    it 'can run custom checks' do
      File.write('Checks', 'check :my_foo_check do ; puts "I AM FOO!" ; end')
      expect { runner.run_specific(%w[my_foo_check]) }.to output(/I AM FOO!/).to_stdout
    end
  end

  describe '#list_checks' do
    before do
      File.write('Checks', 'check :my_foo_check do ; end')
    end

    it 'lists all checks' do
      expect { runner.list_checks }
        .to output(%r{Available checks:$.*^  css$.*^  my_foo_check$}m).to_stdout
    end
  end

  describe '#any_enabled_checks?' do
    subject { runner.any_enabled_checks? }

    context 'no DSL' do
      context 'no deploy checks defined in config' do
        it { is_expected.to be(false) }
      end

      context 'deploy checks defined in config' do
        before do
          File.write('nanoc.yaml', "checking:\n  enabled_checks:\n    - elinks")
        end

        it { is_expected.to be(true) }
      end
    end

    context 'DSL without deploy checks defined' do
      before do
        File.write('Checks', '')
      end

      context 'no deploy checks defined in config' do
        it { is_expected.to be(false) }
      end

      context 'deploy checks defined in config' do
        before do
          File.write('nanoc.yaml', "checking:\n  enabled_checks:\n    - elinks")
        end

        it { is_expected.to be(true) }
      end
    end

    context 'DSL with deploy checks defined' do
      before do
        File.write('Checks', 'deploy_check :ilinks')
      end

      context 'no deploy checks defined in config' do
        it { is_expected.to be(true) }
      end

      context 'deploy checks defined in config' do
        before do
          File.write('nanoc.yaml', "checking:\n  enabled_checks:\n    - elinks")
        end

        it { is_expected.to be(true) }
      end
    end
  end

  describe '#enabled_checks' do
    subject { runner.send(:enabled_checks) }

    context 'no DSL' do
      context 'no deploy checks defined in config' do
        it { is_expected.to be_empty }
      end

      context 'deploy checks defined in config' do
        before do
          File.write('nanoc.yaml', "checking:\n  enabled_checks:\n    - elinks")
        end

        it { is_expected.to contain_exactly(:elinks) }
      end
    end

    context 'DSL without deploy checks defined' do
      before do
        File.write('Checks', '')
      end

      context 'no deploy checks defined in config' do
        it { is_expected.to be_empty }
      end

      context 'deploy checks defined in config' do
        before do
          File.write('nanoc.yaml', "checking:\n  enabled_checks:\n    - elinks")
        end

        it { is_expected.to contain_exactly(:elinks) }
      end
    end

    context 'DSL with deploy checks defined' do
      before do
        File.write('Checks', 'deploy_check :ilinks')
      end

      context 'no deploy checks defined in config' do
        it { is_expected.to contain_exactly(:ilinks) }
      end

      context 'deploy checks defined in config' do
        before do
          File.write('nanoc.yaml', "checking:\n  enabled_checks:\n    - elinks")
        end

        it { is_expected.to match_array(%i[ilinks elinks]) }
      end
    end
  end

  describe '#check_classes_named' do
    subject { runner.send(:check_classes_named, names) }

    context 'given one full name' do
      let(:names) { %w[internal_links] }

      it { is_expected.to eq([Nanoc::Checking::Checks::InternalLinks]) }
    end

    context 'given one full name with dash instead of underscore' do
      let(:names) { %w[internal-links] }

      it { is_expected.to eq([Nanoc::Checking::Checks::InternalLinks]) }
    end

    context 'given one abbreviated name' do
      let(:names) { %w[ilinks] }

      it { is_expected.to eq([Nanoc::Checking::Checks::InternalLinks]) }
    end
  end
end
