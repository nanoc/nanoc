# encoding: utf-8

describe Nanoc::TempFilenameFactory do

  subject do
    Nanoc::TempFilenameFactory.instance
  end

  let(:prefix) { 'foo' }

  before do
    subject.cleanup(prefix)
  end

  describe '#create' do

    it 'should create unique paths' do
      path_a = subject.create(prefix)
      path_b = subject.create(prefix)
      path_a.wont_equal(path_b)
    end

    it 'should return absolute paths' do
      path = subject.create(prefix)
      path.must_match(/\A\//)
    end

    it 'should create the containing directory' do
      Dir[subject.root_dir + '/**/*'].must_equal([])
      path = subject.create(prefix)
      File.directory?(File.dirname(path)).must_equal(true)
    end

    it 'should reuse the same path after cleanup' do
      path_a = subject.create(prefix)
      subject.cleanup(prefix)
      path_b = subject.create(prefix)
      path_a.must_equal(path_b)
    end

  end

  describe '#cleanup' do

    it 'should remove generated files' do
      path_a = subject.create(prefix)
      File.file?(path_a).wont_equal(true) # not yet used

      File.open(path_a, 'w') { |io| io << 'hi!' }
      File.file?(path_a).must_equal(true)

      subject.cleanup(prefix)
      File.file?(path_a).wont_equal(true)
    end

    it 'should eventually delete the root directory' do
      subject.create(prefix)
      File.directory?(subject.root_dir).must_equal(true)

      subject.cleanup(prefix)
      File.directory?(subject.root_dir).wont_equal(true)
    end

  end

  describe 'other instance' do

    let(:other_instance) do
      Nanoc::TempFilenameFactory.new
    end

    it 'should create unique paths across instances' do
      path_a = subject.create(prefix)
      path_b = other_instance.create(prefix)
      path_a.wont_equal(path_b)
    end

  end

end
