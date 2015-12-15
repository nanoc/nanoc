describe 'GH-776', site: true do
  before do
    File.write('content/donkey.md', 'Donkey!')

    File.write('Rules', <<EOS)
  route '/donkey.*', snapshot: :secret do
    '/donkey-secret.html'
  end

  compile '/donkey.*' do
    filter :erb
    snapshot :secret
    write '/donkey.html'
  end

  layout '/foo.*', :erb
EOS
  end

  let(:site) { Nanoc::Int::SiteLoader.new.new_from_cwd }

  before do
    site.compile
  end

  context 'without pruning' do
    it 'writes two files' do
      expect(File.read('output/donkey.html')).to eql('Donkey!')
      expect(File.read('output/donkey-secret.html')).to eql('Donkey!')
    end
  end

  context 'with pruning' do
    before do
      Nanoc::Extra::Pruner.new(site).run
    end

    it 'does not prune written snapshots' do
      expect(File.read('output/donkey.html')).to eql('Donkey!')
      expect(File.read('output/donkey-secret.html')).to eql('Donkey!')
    end
  end
end
