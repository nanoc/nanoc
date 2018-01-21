# frozen_string_literal: true

describe Nanoc::Checking::Runner, site: true do
  subject(:runner) { described_class.new(site) }

  let(:site) { Nanoc::Int::SiteLoader.new.new_from_cwd }

  describe '#any_deploy_checks?' do
    subject { runner.any_deploy_checks? }

    context 'no DSL' do
      it { is_expected.to be(false) }
    end

    context 'DSL defined, but no deploy checks' do
      before do
        File.write('Checks', '')
      end

      it { is_expected.to be(false) }
    end

    context 'DSL defined, with deploy checks' do
      before do
        File.write('Checks', 'deploy_check :ilinks')
      end

      it { is_expected.to be(true) }
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
