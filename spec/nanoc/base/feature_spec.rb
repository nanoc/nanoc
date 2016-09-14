describe Nanoc::Feature do
  describe '.enabled?' do
    subject { described_class.enabled?(feature_name) }

    let(:feature_name) { 'magic' }

    before do
      Nanoc::Feature.reset_caches
      ENV['NANOC_FEATURES'] = ''
    end

    context 'not set' do
      it { is_expected.not_to be }
    end

    context 'set to list not including feature' do
      before { ENV['NANOC_FEATURES'] = 'foo,bar' }
      it { is_expected.not_to be }
    end

    context 'set to all' do
      before { ENV['NANOC_FEATURES'] = 'all' }
      it { is_expected.to be }
    end

    context 'set to list including feature' do
      before { ENV['NANOC_FEATURES'] = 'foo,magic,bar' }
      it { is_expected.to be }
    end
  end

  describe '.all_outdated' do
    it 'refuses outdated features' do
      # If this spec fails, there are features marked as experimental in the previous minor or major
      # release, but not in the current one. Either remove the feature, or mark it as experimental
      # in the current release.
      expect(Nanoc::Feature.all_outdated).to be_empty
    end

    describe 'fake outdated features' do
      before { Nanoc::Feature.define('abc', version: '4.2.x') }
      after { Nanoc::Feature.undefine('abc') }

      it 'detects outdated features' do
        expect(Nanoc::Feature.all_outdated).to eq(['abc'])
      end
    end
  end

  describe '.define and .undefine' do
    it 'can define' do
      Nanoc::Feature.define('testing123', version: '4.3.x')
      expect(Nanoc::Feature::TESTING123).not_to be_nil
    end

    it 'can undefine' do
      Nanoc::Feature.define('testing123', version: '4.3.x')
      Nanoc::Feature.undefine('testing123')
      expect { Nanoc::Feature::TESTING123 }.to raise_error(NameError)
    end
  end
end
