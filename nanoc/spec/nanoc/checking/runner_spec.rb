# frozen_string_literal: true

describe Nanoc::Checking::Runner do
  subject(:runner) { described_class.new(site) }

  let(:site) { double(:site) }

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
