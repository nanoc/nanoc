# frozen_string_literal: true

describe Nanoc::Int::ItemRepWriter do
  describe '#write' do
    let(:raw_path) { 'output/blah.dat' }

    let(:item) { Nanoc::Int::Item.new(orig_content, {}, '/') }

    let(:item_rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.raw_paths = raw_paths
      end
    end

    let(:snapshot_contents) do
      {
        last: Nanoc::Int::TextualContent.new('last content'),
        donkey: Nanoc::Int::TextualContent.new('donkey content'),
      }
    end

    let(:snapshot_name) { :donkey }

    let(:raw_paths) do
      { snapshot_name => [raw_path] }
    end

    let(:snapshot_repo) { Nanoc::Int::SnapshotRepo.new }

    let(:written_paths) { [] }

    subject { described_class.new.write(item_rep, snapshot_repo, snapshot_name, written_paths) }

    before do
      expect(File.directory?('output')).to be_falsy

      snapshot_contents.each_pair do |key, value|
        snapshot_repo.set(item_rep, key, value)
      end
    end

    context 'binary item rep' do
      let(:orig_content) { Nanoc::Int::BinaryContent.new(File.expand_path('foo.dat')) }

      let(:snapshot_contents) do
        {
          last: Nanoc::Int::BinaryContent.new(File.expand_path('input-last.dat')),
          donkey: Nanoc::Int::BinaryContent.new(File.expand_path('input-donkey.dat')),
        }
      end

      before do
        File.write(snapshot_contents[:last].filename, 'binary last stuff')
        File.write(snapshot_contents[:donkey].filename, 'binary donkey stuff')
      end

      it 'copies' do
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:will_write_rep, item_rep, 'output/blah.dat')
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:rep_written, item_rep, true, 'output/blah.dat', true, true)

        subject

        expect(File.read('output/blah.dat')).to eql('binary donkey stuff')
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
      let(:orig_content) { Nanoc::Int::TextualContent.new('Hallo Welt') }

      it 'writes' do
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:will_write_rep, item_rep, 'output/blah.dat')
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:rep_written, item_rep, false, 'output/blah.dat', true, true)

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
