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
end
