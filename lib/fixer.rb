module Nanoc
  class Fixer
    def self.fix_site
      Dir["content/**/index.*"].each do |file|
        FileManager.rename_file(file, file.sub(/\/([^\/]+)\/index\./, '/\1/\1.'))
      end
    end
  end
end
