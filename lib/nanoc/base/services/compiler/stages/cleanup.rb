module Nanoc::Int::Compiler::Stages
  class Cleanup
    def initialize(config)
      @config = config
    end

    def run
      cleanup_temps(Nanoc::Filter::TMP_BINARY_ITEMS_DIR)
      cleanup_temps(Nanoc::Int::ItemRepWriter::TMP_TEXT_ITEMS_DIR)
      cleanup_unused_stores
    end

    private

    def cleanup_temps(dir)
      Nanoc::Int::TempFilenameFactory.instance.cleanup(dir)
    end

    def cleanup_unused_stores
      used_paths = @config.output_dirs.map { |d| Nanoc::Int::Store.tmp_path_prefix(d) }
      all_paths = Dir.glob('tmp/nanoc/*')
      (all_paths - used_paths).each do |obsolete_path|
        FileUtils.rm_rf(obsolete_path)
      end
    end
  end
end
