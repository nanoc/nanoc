describe 'GH-1171', site: true, stdio: true do
  before do
    File.write('nanoc.yaml', <<EOS)
data_sources:
  -
    type: filesystem
    encoding: utf-8
EOS
  end

  context 'UTF-8 code in ASCII env' do
    before do
      File.write('content/hi.md', '<%= ::EMOJI_🔥 %>', encoding: 'utf-8')
      File.write('lib/asdf.rb', 'EMOJI_🔥 = "hot"', encoding: 'utf-8')

      File.write('Rules', <<EOS)
compile '/**/*' do
  filter :erb
  write '/last.html'
end
EOS
    end

    around do |ex|
      orig_encoding = Encoding.default_external
      Encoding.default_external = 'ASCII'
      ex.run
      Encoding.default_external = orig_encoding
    end

    it 'does not crash' do
      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/last.html')).to eql('hot')
    end
  end

  context 'ISO 8859-1 code UTF-8 env' do
    before do
      File.write('content/hi.md', '<%= ::BRØKEN %>')
      File.write('lib/asdf.rb', "# encoding: iso-8859-1\n\nBRØKEN = 1", encoding: 'ISO-8859-1')

      File.write('Rules', <<EOS)
compile '/**/*' do
  filter :erb
  write '/last.html'
end
EOS
    end

    it 'detects manually specified encodings' do
      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/last.html')).to eql('1')
    end
  end
end
