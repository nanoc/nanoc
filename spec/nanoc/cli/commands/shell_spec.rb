describe Nanoc::CLI::Commands::Shell do
  describe '#env_for' do
    subject { described_class.env_for(site) }

    let(:site) do
      double(
        :site,
        items: [],
        layouts: [],
        config: nil,
      )
    end

    it 'returns views' do
      expect(subject[:items]).to be_a(Nanoc::ItemCollectionView)
      expect(subject[:layouts]).to be_a(Nanoc::LayoutCollectionView)
      expect(subject[:config]).to be_a(Nanoc::ConfigView)
    end
  end
end
