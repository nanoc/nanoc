# frozen_string_literal: true

describe Nanoc::Int::Compiler::Stages::Cleanup do
  let(:stage) { described_class.new(config) }

  let(:config) do
    Nanoc::Int::Configuration.new.with_defaults
  end

  describe '#run' do
    subject { stage.run }

    it 'removes temporary binary items' do
      a = Nanoc::Int::TempFilenameFactory.instance.create(Nanoc::Filter::TMP_BINARY_ITEMS_DIR)
      File.write(a, 'hello there')

      expect { subject }
        .to change { File.file?(a) }
        .from(true).to(false)
    end

    it 'removes temporary textual items' do
      a = Nanoc::Int::TempFilenameFactory.instance.create(Nanoc::Int::ItemRepWriter::TMP_TEXT_ITEMS_DIR)
      File.write(a, 'hello there')

      expect { subject }
        .to change { File.file?(a) }
        .from(true).to(false)
    end

    shared_examples 'an old store' do
      it 'removes the old store' do
        FileUtils.mkdir_p('tmp')
        File.write('tmp/' + store_name, 'stuff')

        expect { subject }
          .to change { File.file?('tmp/' + store_name) }
          .from(true).to(false)
      end
    end

    context 'tmp/checksums' do
      let(:store_name) { 'checksums' }
      it_behaves_like 'an old store'
    end

    context 'tmp/compiled_content' do
      let(:store_name) { 'compiled_content' }
      it_behaves_like 'an old store'
    end

    context 'tmp/dependencies' do
      let(:store_name) { 'dependencies' }
      it_behaves_like 'an old store'
    end

    context 'tmp/outdatedness' do
      let(:store_name) { 'outdatedness' }
      it_behaves_like 'an old store'
    end

    context 'tmp/action_sequence' do
      let(:store_name) { 'action_sequence' }
      it_behaves_like 'an old store'
    end

    context 'tmp/somethingelse' do
      it 'does not removes the store' do
        FileUtils.mkdir_p('tmp')
        File.write('tmp/somethingelse', 'stuff')

        expect { subject }
          .not_to change { File.file?('tmp/somethingelse') }
      end
    end

    it 'removes stores for unused output paths' do
      FileUtils.mkdir_p('tmp/nanoc/2f0692fb1a1d')
      FileUtils.mkdir_p('tmp/nanoc/1a2195bfef6c')
      FileUtils.mkdir_p('tmp/nanoc/1029d67644815')

      expect { subject }
        .to change { Dir.glob('tmp/nanoc/*').sort }
        .from(['tmp/nanoc/1029d67644815', 'tmp/nanoc/1a2195bfef6c', 'tmp/nanoc/2f0692fb1a1d'])
        .to(['tmp/nanoc/1029d67644815'])
    end
  end
end
