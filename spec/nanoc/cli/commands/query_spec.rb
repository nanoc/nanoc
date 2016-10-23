describe Nanoc::CLI::Commands::Query, site: true, stdio: true do
  describe '#run' do
    before do
      # Prevent double-loading
      expect(Nanoc::CLI).to receive(:setup)
    end

    it 'can be invoked' do
      File.write('content/stuff.md', 'hi')

      expect { Nanoc::CLI.run(['query', '@items.to_a.first.identifier']) }.to output("/stuff.md\n").to_stdout
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
