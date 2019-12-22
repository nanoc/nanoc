# frozen_string_literal: true

describe Nanoc::Core::Feature do
  describe '.enabled?' do
    subject { described_class.enabled?(feature_name) }

    let(:feature_name) { 'magic' }

    before do
      described_class.reset_caches
      ENV['NANOC_FEATURES'] = +''
    end

    context 'not set' do
      it { is_expected.to be(false) }
    end

    context 'set to list not including feature' do
      before { ENV['NANOC_FEATURES'] = 'foo,bar' }

      it { is_expected.to be(false) }
    end

    context 'set to all' do
      before { ENV['NANOC_FEATURES'] = 'all' }

      it { is_expected.to be(true) }
    end

    context 'set to list including feature' do
      before { ENV['NANOC_FEATURES'] = 'foo,magic,bar' }

      it { is_expected.to be(true) }
    end
  end

  describe '.enable' do
    subject do
      described_class.enable(feature_name) do
        described_class.enabled?(feature_name)
      end
    end

    let(:feature_name) { 'magic' }

    before do
      described_class.reset_caches
      ENV['NANOC_FEATURES'] = +''
    end

    context 'not set' do
      it { is_expected.to be(true) }

      it 'unsets afterwards' do
        expect(described_class.enabled?(feature_name)).to be(false)
      end
    end

    context 'set to list not including feature' do
      before { ENV['NANOC_FEATURES'] = 'foo,bar' }

      it { is_expected.to be(true) }

      it 'unsets afterwards' do
        expect(described_class.enabled?(feature_name)).to be(false)
      end
    end

    context 'set to all' do
      before { ENV['NANOC_FEATURES'] = 'all' }

      it { is_expected.to be(true) }
    end

    context 'set to list including feature' do
      before { ENV['NANOC_FEATURES'] = 'foo,magic,bar' }

      it { is_expected.to be(true) }
    end
  end

  describe '.all_outdated' do
    it 'refuses outdated features' do
      # If this spec fails, there are features marked as experimental in the previous minor or major
      # release, but not in the current one. Either remove the feature, or mark it as experimental
      # in the current release.
      expect(described_class.all_outdated).to be_empty
    end

    describe 'fake outdated features' do
      before { described_class.define('abc', version: '4.2.x') }

      after { described_class.undefine('abc') }

      it 'detects outdated features' do
        expect(described_class.all_outdated).to eq(['abc'])
      end
    end
  end

  describe '.define and .undefine' do
    let(:feature_name) { 'testing123' }

    after { described_class.undefine(feature_name) if defined?(Nanoc::Core::Feature::TESTING123) }

    it 'can define' do
      described_class.define(feature_name, version: '4.3.x')
      expect(Nanoc::Core::Feature::TESTING123).not_to be_nil
    end

    it 'can undefine' do
      described_class.define(feature_name, version: '4.3.x')
      described_class.undefine(feature_name)
      expect { Nanoc::Core::Feature::TESTING123 }.to raise_error(NameError)
    end
  end
end
