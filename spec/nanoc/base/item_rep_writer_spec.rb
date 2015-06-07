describe Nanoc::Int::ItemRepWriter do
  describe '#write' do
    let(:raw_path) { 'output/blah.dat' }

    let(:item) { Nanoc::Int::Item.new(orig_content, {}, '/') }

    let(:item_rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.content = content
        ir.temporary_filenames.replace(temporary_filenames)
      end
    end

    let(:content) do
      { last: 'last content' }
    end

    let(:temporary_filenames) do
      {}
    end

    subject { described_class.new.write(item_rep, raw_path) }

    before do
      expect(File.directory?('output')).to be_falsy
    end

    context 'binary item rep' do
      let(:orig_content) { Nanoc::Int::BinaryContent.new('/foo.dat') }

      let(:temporary_filenames) { { last: 'input.dat' } }

      it 'copies' do
        File.write(temporary_filenames[:last], 'binary stuff')

        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:will_write_rep, item_rep, 'output/blah.dat')
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:rep_written, item_rep, 'output/blah.dat', true, true)

        subject

        expect(File.read('output/blah.dat')).to eql('binary stuff')
      end

      context 'output file already exists' do
        let(:old_mtime) { (Time.now - 600).to_i }

        before do
          File.write(temporary_filenames[:last], 'binary stuff')

          FileUtils.mkdir_p('output')
          File.write('output/blah.dat', old_content)
          FileUtils.touch('output/blah.dat', mtime: old_mtime)
        end

        context 'file is identical' do
          let(:old_content) { 'binary stuff' }

          it 'keeps mtime' do
            subject
            expect(File.mtime('output/blah.dat')).to eql(old_mtime)
          end
        end

        context 'file is not identical' do
          let(:old_content) { 'other binary stuff' }

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
          .with(:rep_written, item_rep, 'output/blah.dat', true, true)

        subject

        expect(File.read('output/blah.dat')).to eql('last content')
      end

      context 'output file already exists' do
        let(:old_mtime) { (Time.now - 600).to_i }

        before do
          FileUtils.mkdir_p('output')
          File.write('output/blah.dat', old_content)
          FileUtils.touch('output/blah.dat', mtime: old_mtime)
        end

        context 'file is identical' do
          let(:old_content) { 'last content' }

          it 'keeps mtime' do
            subject
            expect(File.mtime('output/blah.dat')).to eql(old_mtime)
          end
        end

        context 'file is not identical' do
          let(:old_content) { 'other last content' }

          it 'updates mtime' do
            subject
            expect(File.mtime('output/blah.dat')).to be > (Time.now - 1)
          end
        end
      end
    end
  end
end
