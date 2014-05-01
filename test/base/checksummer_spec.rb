# encoding: utf-8

require 'tempfile'

describe Nanoc::Checksummer do

  subject { Nanoc::Checksummer.new }

  CHECKSUM_REGEX = /\A[0-9a-f]{40}\Z/

  describe 'for String' do

    it 'should checksum strings' do
      subject.calc('foo').must_equal('fb993f056be461ce93d6a846692c9fdfceb50b21')
    end

  end

  describe 'for Array' do

    it 'should checksum arrays' do
      subject.calc([1, 'a', :a]).must_equal '98bf936aa36c11e88f9169683e00ad0287d3d728'
    end

    it 'should take order into account when checksumming arrays' do
      subject.calc([:a, 'a', 1]).wont_equal(subject.calc([1, 'a', :a]))
    end

    it 'should checksum non-serializable arrays' do
      subject.calc([-> {}]).must_match(CHECKSUM_REGEX)
    end

  end

  describe 'for Hash' do

    it 'should checksum hashes' do
      subject.calc({ a: 1, b: 2 }).must_equal 'fc42333a651603781e959a1392731f6345591fee'
    end

    it 'should take order into account when checksumming hashes' do
      subject.calc({ a: 1, b: 2 }).wont_equal(subject.calc({ b: 2, a: 1 }))
    end

    it 'should checksum non-serializable hashes' do
      subject.calc({ a: ->{} }).must_match(CHECKSUM_REGEX)
    end

  end

  describe 'for Pathname' do

    let(:file)            { Tempfile.new('foo') }
    let(:filename)        { file.path }
    let(:pathname)        { Pathname.new(filename) }
    let(:atime)           { 1234567890 }
    let(:mtime)           { 1234567890 }
    let(:data)            { 'stuffs' }
    let(:normal_checksum) { '4c7cbb636f28ae8a2ffcabcfc53eb070c9d7affb' }

    before do
      file.write(data)
      file.close
      File.utime(atime, mtime, filename)
    end

    after do
      file.unlink
    end

    describe 'does not exist' do

      let(:non_existing_filename) { 'askldjfklaslasdfkjsajdf' }
      let(:pathname)              { Pathname.new(filename) }

      it 'should still checksum' do
        subject.calc(pathname).must_equal('4c7cbb636f28ae8a2ffcabcfc53eb070c9d7affb')
      end

    end

    it 'should get the mtime right' do
      stat = File.stat(filename)
      stat.mtime.to_i.must_equal(mtime)
    end

    it 'should get the file size right' do
      stat = File.stat(filename)
      stat.size.must_equal(6)
    end

    it 'should checksum binary content' do
      subject.calc(pathname).must_equal(normal_checksum)
    end

    describe 'if the mtime changes' do

      let(:mtime) { 1333333333 }

      it 'should have a different checksum' do
        subject.calc(pathname).must_match(CHECKSUM_REGEX)
        subject.calc(pathname).wont_equal(normal_checksum)
      end

    end

    describe 'if the content changes, but not the file size' do

      let(:data) { 'STUFF!' }

      it 'should have the same checksum' do
        subject.calc(pathname).must_equal(normal_checksum)
      end

    end

    describe 'if the file size changes' do

      let(:data) { 'stuff and stuff and stuff!!!' }

      it 'should have a different checksum' do
        subject.calc(pathname).must_match(CHECKSUM_REGEX)
        subject.calc(pathname).wont_equal(normal_checksum)
      end

    end

  end

  it 'should not have the same checksum for same content but different class'

  describe 'for Nanoc::RulesCollection' do

    let(:filename) { 'Rules' }
    let(:data)     { 'STUFF!' }

    before do
      File.open(filename, 'w') { |io| io << data }
    end

    let(:rules_collection) do
      coll = Nanoc::RulesCollection.new(nil)
      coll.data = data
      coll
    end

    it 'should calculate' do
      subject.calc(rules_collection).must_equal('af84b00e90a9e6c6813de664da040e25c8a94d95')
    end

  end

  describe 'for Nanoc::CodeSnippet' do

    let(:data)         { 'asdf' }
    let(:filename)     { File.expand_path('bob.txt') }
    let(:code_snippet) { Nanoc::CodeSnippet.new(data, filename) }

    it 'should checksum the data' do
      subject.calc(code_snippet).must_equal('652a39e8216805c360883b1639f2cbaae1f6b05d')
    end

  end

  describe 'for Nanoc::Configuration' do

    let(:wrapped)       { { a: 1, b: 2 } }
    let(:configuration) { Nanoc::Configuration.new(wrapped) }

    it 'should checksum the hash' do
      subject.calc(configuration).must_equal('07b8b53c563199afd649226e18775abea410e2a0')
    end

  end

  describe 'for Nanoc::Item' do

    let(:content)         { 'asdf' }
    let(:filename)        { File.expand_path('bob.txt') }
    let(:attributes)      { { a: 1, b: 2 } }
    let(:identifier)      { '/foo/' }
    let(:item)            { Nanoc::Item.new(content, attributes, identifier) }
    let(:normal_checksum) { '276ba494988670ebaffe3daef665dfedadeb5f35' }

    it 'should checksum item' do
      subject.calc(item).must_equal(normal_checksum)
    end

    describe 'with changed attributes' do

      let(:attributes) { { x: 4, y: 5 } }

      it 'should have a different checksum' do
        subject.calc(item).must_match(CHECKSUM_REGEX)
        subject.calc(item).wont_equal(normal_checksum)
      end

    end

    describe 'with changed content' do

      let(:content) { 'something drastically different' }

      it 'should have a different checksum' do
        subject.calc(item).must_match(CHECKSUM_REGEX)
        subject.calc(item).wont_equal(normal_checksum)
      end

    end

  end

  describe 'for any other classes' do

    let(:unchecksumable_object) { Object.new }

    it 'should raise an exception' do
      assert_raises(Nanoc::Checksummer::UnchecksummableError) do
        subject.calc(unchecksumable_object)
      end
    end

  end

end
