# encoding: utf-8

require 'tempfile'

describe Nanoc::Int::Checksummer do
  subject { Nanoc::Int::Checksummer }

  CHECKSUM_REGEX = /\A[0-9a-zA-Z\/+]+=*\Z/

  describe 'for String' do
    it 'should checksum strings' do
      subject.calc('foo').must_equal('+5k/BWvkYc6T1qhGaSyf3861CyE=')
    end
  end

  describe 'for Array' do
    it 'should checksum arrays' do
      subject.calc([1, 'a', :a]).must_equal 'YtWOEFUAMQritkY38KXHFZM/n2E='
    end

    it 'should take order into account when checksumming arrays' do
      subject.calc([:a, 'a', 1]).wont_equal(subject.calc([1, 'a', :a]))
    end

    it 'should checksum non-serializable arrays' do
      subject.calc([-> {}]).must_match(CHECKSUM_REGEX)
    end

    it 'should checksum recursive arrays' do
      array = [:a]
      array << array
      subject.calc(array).must_equal('mR3c98xA5ecazxx+M3h0Ss4/J20=')
    end
  end

  describe 'for Hash' do
    it 'should checksum hashes' do
      subject.calc({ a: 1, b: 2 }).must_equal 'qY8fW6gWK7F1XQ9MLrx3Gru/RTY='
    end

    it 'should take order into account when checksumming hashes' do
      subject.calc({ a: 1, b: 2 }).wont_equal(subject.calc({ b: 2, a: 1 }))
    end

    it 'should checksum non-serializable hashes' do
      subject.calc({ a: -> {} }).must_match(CHECKSUM_REGEX)
    end

    it 'should checksum recursive hash keys' do
      hash = {}
      hash[hash] = 123
      subject.calc(hash).must_equal('mKucWMhRtR/FHWNqR/EErF4qgTk=')
    end

    it 'should checksum recursive hash values' do
      hash = {}
      hash[123] = hash
      subject.calc(hash).must_equal('PBiDX0nWnV+DAYB+w+xM0Kf21ZM=')
    end
  end

  describe 'for Pathname' do
    let(:file)            { Tempfile.new('foo') }
    let(:filename)        { file.path }
    let(:pathname)        { Pathname.new(filename) }
    let(:atime)           { 1_234_567_890 }
    let(:mtime)           { 1_234_567_890 }
    let(:data)            { 'stuffs' }
    let(:normal_checksum) { 'THy7Y28oroov/KvPxT6wcMnXr/s=' }

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
        subject.calc(pathname).must_equal(normal_checksum)
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
      let(:mtime) { 1_333_333_333 }

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

  describe 'for Nanoc::Int::RulesCollection' do
    let(:data)            { 'STUFF!' }
    let(:normal_checksum) { 'Y6mX13i8ZEd4a11xRPc2yNQSRDs=' }

    let(:rules_collection) do
      coll = Nanoc::Int::RulesCollection.new(nil)
      coll.data = data
      coll
    end

    it 'should calculate' do
      subject.calc(rules_collection).must_equal(normal_checksum)
    end

    describe 'if the content changes' do
      let(:data) { 'Other stuff!' }

      it 'should have a different checksum' do
        subject.calc(rules_collection).must_match(CHECKSUM_REGEX)
        subject.calc(rules_collection).wont_equal(normal_checksum)
      end
    end
  end

  describe 'for Nanoc::Int::CodeSnippet' do
    let(:data)            { 'asdf' }
    let(:filename)        { File.expand_path('bob.txt') }
    let(:code_snippet)    { Nanoc::Int::CodeSnippet.new(data, filename) }
    let(:normal_checksum) { 's6oZ1xLVekKDVhYrXsJuHChFjek=' }

    it 'should checksum the data' do
      subject.calc(code_snippet).must_equal(normal_checksum)
    end

    describe 'if the filename changes' do
      let(:filename) { File.expand_path('george.txt') }

      it 'should have the same checksum' do
        subject.calc(code_snippet).must_equal(normal_checksum)
      end
    end

    describe 'if the content changes' do
      let(:data) { 'Other stuff!' }

      it 'should have a different checksum' do
        subject.calc(code_snippet).must_match(CHECKSUM_REGEX)
        subject.calc(code_snippet).wont_equal(normal_checksum)
      end
    end
  end

  describe 'for Nanoc::Int::Configuration' do
    let(:wrapped)         { { a: 1, b: 2 } }
    let(:configuration)   { Nanoc::Int::Configuration.new(wrapped) }
    let(:normal_checksum) { 'S00TDYQNxxeva06T8Iyl8Q9iu3Q=' }

    it 'should checksum the hash' do
      subject.calc(configuration).must_equal(normal_checksum)
    end

    describe 'if the content changes' do
      let(:wrapped) { { a: 666, b: 2 } }

      it 'should have a different checksum' do
        subject.calc(configuration).must_match(CHECKSUM_REGEX)
        subject.calc(configuration).wont_equal(normal_checksum)
      end
    end
  end

  describe 'for Nanoc::Int::Item' do
    let(:content)         { 'asdf' }
    let(:filename)        { File.expand_path('bob.txt') }
    let(:attributes)      { { a: 1, b: 2 } }
    let(:identifier)      { '/foo/' }
    let(:item)            { Nanoc::Int::Item.new(content, attributes, identifier) }
    let(:normal_checksum) { '6eNdrrKiqPtsZKWDqGcmzsyzecU=' }

    it 'should checksum item' do
      subject.calc(item).must_equal(normal_checksum)
    end

    describe 'with recursive attributes' do
      it 'should checksum' do
        item.attributes[:a] = item
        subject.calc(item).must_match(CHECKSUM_REGEX)
        subject.calc(item).wont_equal(normal_checksum)
      end
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

  describe 'for other marshal-able classes' do
    let(:obj) { :foobar }

    it 'should checksum' do
      subject.calc(obj).must_match(CHECKSUM_REGEX)
    end
  end

  describe 'for other non-marshal-able classes' do
    let(:obj) { proc {} }

    it 'should checksum' do
      subject.calc(obj).must_match(CHECKSUM_REGEX)
    end
  end
end
