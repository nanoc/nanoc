describe Nanoc::Feature do
  describe '.enabled?' do
    subject { described_class.enabled?(feature_name) }

    let(:feature_name) { 'magic' }

    context 'disabled' do
      context 'not set' do
        it { is_expected.not_to be }
      end

      %w(0 n N no No NO false False fAlSe FALSE donkey).each do |val|
        context "set to #{val}" do
          before { ENV['NANOC_FEATURE_MAGIC'] = val }
          it { is_expected.not_to be }
        end
      end
    end

    context 'enabled' do
      %w(1 y Y yes yEs YES t True tRuE TRUE).each do |val|
        context "set to #{val}" do
          before { ENV['NANOC_FEATURE_MAGIC'] = val }
          it { is_expected.to be }
        end
      end
    end
  end
end
