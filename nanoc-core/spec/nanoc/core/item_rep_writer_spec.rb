# frozen_string_literal: true

describe Nanoc::Core::ItemRepWriter do
  describe '#write' do
    subject { described_class.new.write(item_rep, compiled_content_store, snapshot_name, written_paths) }

    let(:raw_path) { Dir.getwd + '/output/blah.dat' }

    let(:item) { Nanoc::Core::Item.new(orig_content, {}, '/foo') }

    let(:item_rep) do
      Nanoc::Core::ItemRep.new(item, :default).tap do |ir|
        ir.raw_paths = raw_paths
      end
    end

    let(:snapshot_contents) do
      {
        last: Nanoc::Core::TextualContent.new('last content'),
        donkey: Nanoc::Core::TextualContent.new('donkey content'),
      }
    end

    let(:snapshot_name) { :donkey }

    let(:raw_paths) do
      { snapshot_name => [raw_path] }
    end

    let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }

    let(:written_paths) { [] }

    before do
      expect(File.directory?('output')).to be_falsy

      snapshot_contents.each_pair do |key, value|
        compiled_content_store.set(item_rep, key, value)
      end
    end

    context 'binary item rep' do
      let(:orig_content) { Nanoc::Core::BinaryContent.new(File.expand_path('foo.dat')) }

      let(:snapshot_contents) do
        {
          last: Nanoc::Core::BinaryContent.new(File.expand_path('input-last.dat')),
          donkey: Nanoc::Core::BinaryContent.new(File.expand_path('input-donkey.dat')),
        }
      end

      before do
        File.write(snapshot_contents[:last].filename, 'binary last stuff')
        File.write(snapshot_contents[:donkey].filename, 'binary donkey stuff')
      end

      it 'copies contents' do
        expect(Nanoc::Core::NotificationCenter).to receive(:post)
          .with(:rep_write_started, item_rep, Dir.getwd + '/output/blah.dat')
        expect(Nanoc::Core::NotificationCenter).to receive(:post)
          .with(:rep_write_ended, item_rep, true, Dir.getwd + '/output/blah.dat', true, true)

        subject

        expect(File.read('output/blah.dat')).to eql('binary donkey stuff')
      end

      it 'uses hard links' do
        subject

        input = File.stat(snapshot_contents[:donkey].filename)
        output = File.stat('output/blah.dat')

        expect(input.ino).to eq(output.ino)
      end

      context 'output file already exists' do
        let(:old_mtime) { Time.at((Time.now - 600).to_i) }

        before do
          FileUtils.mkdir_p('output')
          File.write('output/blah.dat', old_content)
          FileUtils.touch('output/blah.dat', mtime: old_mtime)
        end

        context 'file is identical' do
          let(:old_content) { 'binary donkey stuff' }

          it 'keeps mtime' do
            subject
            expect(File.mtime('output/blah.dat')).to eql(old_mtime)
          end
        end

        context 'file is not identical' do
          let(:old_content) { 'other binary donkey stuff' }

          it 'updates mtime' do
            subject
            expect(File.mtime('output/blah.dat')).to be > (Time.now - 1)
          end
        end
      end
    end

    context 'textual item rep' do
      let(:orig_content) { Nanoc::Core::TextualContent.new('Hallo Welt') }

      it 'writes' do
        expect(Nanoc::Core::NotificationCenter).to receive(:post)
          .with(:rep_write_started, item_rep, Dir.getwd + '/output/blah.dat')
        expect(Nanoc::Core::NotificationCenter).to receive(:post)
          .with(:rep_write_ended, item_rep, false, Dir.getwd + '/output/blah.dat', true, true)

        subject

        expect(File.read('output/blah.dat')).to eql('donkey content')
      end

      context 'output file already exists' do
        let(:old_mtime) { Time.at((Time.now - 600).to_i) }

        before do
          FileUtils.mkdir_p('output')
          File.write('output/blah.dat', old_content)
          FileUtils.touch('output/blah.dat', mtime: old_mtime)
        end

        context 'file is identical' do
          let(:old_content) { 'donkey content' }

          it 'keeps mtime' do
            subject
            expect(File.mtime('output/blah.dat')).to eql(old_mtime)
          end
        end

        context 'file is not identical' do
          let(:old_content) { 'other donkey content' }

          it 'updates mtime' do
            subject
            expect(File.mtime('output/blah.dat')).to be > (Time.now - 1)
          end
        end
      end
    end
  end
end
