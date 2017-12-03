# frozen_string_literal: true

describe Nanoc::Int::TempFilenameFactory do
  subject(:factory) { described_class.new }

  let(:prefix) { 'foo' }

  describe '#create' do
    it 'creates unique paths' do
      path_a = subject.create(prefix)
      path_b = subject.create(prefix)

      expect(path_a).not_to eq(path_b)
    end

    it 'returns absolute paths' do
      path = subject.create(prefix)

      expect(path).to match(/\A\//)
    end

    it 'creates the containing directory' do
      expect(Dir[subject.root_dir + '/**/*']).to be_empty

      path = subject.create(prefix)

      expect(File.directory?(File.dirname(path))).to be(true)
    end

    it 'reuses the same path after cleanup' do
      path_a = subject.create(prefix)

      subject.cleanup(prefix)

      path_b = subject.create(prefix)
      expect(path_a).to eq(path_b)
    end

    it 'does not create the file' do
      path = subject.create(prefix)
      expect(File.file?(path)).not_to be(true)
    end
  end

  describe '#cleanup' do
    subject { factory.cleanup(prefix) }

    let!(:path) { factory.create(prefix) }

    before { File.write(path, 'hello') }

    def files
      Dir[factory.root_dir + '/**/*'].select { |fn| File.file?(fn) }
    end

    it 'removes generated files' do
      expect { subject }.to change { files }.from([path]).to([])
    end

    context 'files with other prefixes exist' do
      before do
        factory.create('donkey')
      end

      it 'does not delete root dir' do
        expect(File.directory?(factory.root_dir)).to be(true)
        expect { subject }.not_to change { File.directory?(factory.root_dir) }
      end
    end

    context 'no files with other prefixes exist' do
      it 'deletes root dir' do
        expect { subject }.to change { File.directory?(factory.root_dir) }.from(true).to(false)
      end
    end
  end

  describe 'other instance' do
    let(:other_instance) do
      Nanoc::Int::TempFilenameFactory.new
    end

    it 'creates unique paths across instances' do
      path_a = subject.create(prefix)
      path_b = other_instance.create(prefix)
      expect(path_a).not_to eq(path_b)
    end
  end
end
