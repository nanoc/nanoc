describe Nanoc::CLI::Commands::Shell, site: true do
  describe '#run' do
    before do
      # Prevent double-loading
      expect(Nanoc::CLI).to receive(:setup)
    end

    it 'can be invoked' do
      context = Object.new
      allow(Nanoc::Int::Context).to receive(:new).with(anything).and_return(context)
      expect(context).to receive(:pry)

      Nanoc::CLI.run(['shell'])
    end
  end

  describe '#env_for_site' do
    subject { described_class.env_for_site(site) }

    let(:site) do
      double(
        :site,
        items: [],
        layouts: [],
        config: nil,
      )
    end

    it 'returns views' do
      expect(subject[:items]).to be_a(Nanoc::ItemCollectionWithRepsView)
      expect(subject[:layouts]).to be_a(Nanoc::LayoutCollectionView)
      expect(subject[:config]).to be_a(Nanoc::ConfigView)
    end
  end
end
