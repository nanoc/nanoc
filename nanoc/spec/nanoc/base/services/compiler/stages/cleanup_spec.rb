# frozen_string_literal: true

describe Nanoc::Int::Compiler::Stages::Cleanup do
  let(:stage) { described_class.new(config.output_dirs) }

  let(:config) do
    Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults
  end

  describe '#run' do
    subject { stage.run }

    def gen_hash(path)
      Digest::SHA1.hexdigest(File.absolute_path(path))[0..12]
    end

    it 'removes temporary binary items' do
      a = Nanoc::Core::TempFilenameFactory.instance.create(Nanoc::Filter::TMP_BINARY_ITEMS_DIR)
      File.write(a, 'hello there')

      expect { subject }
        .to change { File.file?(a) }
        .from(true).to(false)
    end

    it 'removes temporary textual items' do
      a = Nanoc::Core::TempFilenameFactory.instance.create(Nanoc::Core::ItemRepWriter::TMP_TEXT_ITEMS_DIR)
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
      default_dir = "tmp/nanoc/#{gen_hash(Dir.getwd + '/output')}"
      prod_dir = "tmp/nanoc/#{gen_hash(Dir.getwd + '/output_production')}"
      staging_dir = "tmp/nanoc/#{gen_hash(Dir.getwd + '/output_staging')}"

      FileUtils.mkdir_p(default_dir)
      FileUtils.mkdir_p(prod_dir)
      FileUtils.mkdir_p(staging_dir)

      expect { subject }
        .to change { Dir.glob('tmp/nanoc/*').sort }
        .from([default_dir, prod_dir, staging_dir].sort)
        .to([default_dir])
    end
  end
end
