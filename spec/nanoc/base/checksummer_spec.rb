require 'tempfile'

describe Nanoc::Int::Checksummer::VerboseDigest do
  let(:digest) { described_class.new }

  it 'concatenates' do
    digest.update('foo')
    digest.update('bar')
    expect(digest.to_s).to eql('foobar')
  end
end

describe Nanoc::Int::Checksummer::CompactDigest do
  let(:digest) { described_class.new }

  it 'uses SHA1 and Base64' do
    digest.update('foo')
    digest.update('bar')
    expect(digest.to_s).to eql(Digest::SHA1.base64digest('foobar'))
  end
end

describe Nanoc::Int::Checksummer do
  subject { described_class.calc(obj, Nanoc::Int::Checksummer::VerboseDigest) }

  context 'String' do
    let(:obj) { 'hello' }
    it { is_expected.to eql('Stringhello') }
  end

  context 'Array' do
    let(:obj) { %w( hello goodbye ) }
    it { is_expected.to eql('ArrayelemStringhelloelemStringgoodbye') }

    context 'different order' do
      let(:obj) { %w( goodbye hello ) }
      it { is_expected.to eql('ArrayelemStringgoodbyeelemStringhello') }
    end

    context 'recursive' do
      let(:obj) { [].tap { |arr| arr << ['hello', arr] } }
      it { is_expected.to eql('ArrayelemArrayelemStringhelloelemArrayrecur') }
    end

    context 'non-serializable' do
      let(:obj) { [-> {}] }
      it { is_expected.to match(/\AArrayelemProc#<Proc:0x.*@.*:\d+.*>\z/) }
    end
  end

  context 'Hash' do
    let(:obj) { { 'a' => 'foo', 'b' => 'bar' } }
    it { is_expected.to eql('HashkeyStringavalueStringfookeyStringbvalueStringbar') }

    context 'different order' do
      let(:obj) { { 'b' => 'bar', 'a' => 'foo' } }
      it { is_expected.to eql('HashkeyStringbvalueStringbarkeyStringavalueStringfoo') }
    end

    context 'non-serializable' do
      let(:obj) { { 'a' => -> {} } }
      it { is_expected.to match(/\AHashkeyStringavalueProc#<Proc:0x.*@.*:\d+.*>\z/) }
    end

    context 'recursive values' do
      let(:obj) { {}.tap { |hash| hash['a'] = hash } }
      it { is_expected.to eql('HashkeyStringavalueHashrecur') }
    end

    context 'recursive keys' do
      let(:obj) { {}.tap { |hash| hash[hash] = 'hello' } }
      it { is_expected.to eql('HashkeyHashrecurvalueStringhello') }
    end
  end

  context 'Pathname' do
    let(:obj) { ::Pathname.new(filename) }

    let(:filename) { '/tmp/whatever' }
    let(:mtime) { 200 }
    let(:data) { 'stuffs' }
    let(:normal_checksum) { 'THy7Y28oroov/KvPxT6wcMnXr/s=' }

    before do
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, data)
      File.utime(mtime, mtime, filename)
    end

    it { is_expected.to eql('FakeFS::Pathname6-200') }

    context 'does not exist' do
      before do
        FileUtils.rm_rf(filename)
      end

      it { is_expected.to eql('FakeFS::Pathname???') }
    end

    context 'different data' do
      let(:data) { 'other stuffs :o' }
      it { is_expected.to eql('FakeFS::Pathname15-200') }
    end
  end

  context 'Nanoc::Int::RulesCollection' do
    let(:obj) do
      Nanoc::Int::RulesCollection.new(nil).tap { |rc| rc.data = data }
    end

    let(:data) { 'STUFF!' }

    it { is_expected.to eql('Nanoc::Int::RulesCollectionStringSTUFF!') }
  end

  context 'Nanoc::Int::CodeSnippet' do
    let(:obj) { Nanoc::Int::CodeSnippet.new('asdf', '/bob.rb') }
    it { is_expected.to eql('Nanoc::Int::CodeSnippetStringasdf') }
  end

  context 'Nanoc::Int::Configuration' do
    let(:obj) { Nanoc::Int::Configuration.new({ 'foo' => 'bar' }) }
    it { is_expected.to eql('Nanoc::Int::ConfigurationkeyStringfoovalueStringbar') }
  end

  context 'Nanoc::Int::Item' do
    # TODO: checksum Symbols without marshaling

    let(:obj) { Nanoc::Int::Item.new('asdf', { 'foo' => 'bar' }, '/foo.md') }

    it { is_expected.to eql("Nanoc::Int::ItemcontentStringasdfattributesHashkeySymbol\u0004\b:\bfoovalueStringbar") }

    context 'recursive attributes' do
      before do
        obj.attributes[:foo] = obj
      end

      it { is_expected.to eql("Nanoc::Int::ItemcontentStringasdfattributesHashkeySymbol\u0004\b:\bfoovalueNanoc::Int::Itemrecur") }
    end
  end

  # TODO: Nanoc::Int::Layout

  context 'other marshal-able classes' do
    let(:obj) { klass.new('hello') }

    let(:klass) do
      Class.new do
        def initialize(a)
          @a = a
        end
      end
    end

    it { is_expected.to match(/\A#<Class:.*>#<#<Class:.*>:.* @a=\"hello\">\z/) }
  end

  context 'other non-marshal-able classes' do
    let(:obj) { proc {} }
    it { is_expected.to match(/\AProc#<Proc:0x.*@.*:\d+.*>\z/) }
  end
end
