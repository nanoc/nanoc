module Nanoc
  class Fixer

    def self.check_site
      Nanoc::Application.ensure_in_site

      Dir["content/**/index.*"].each do |file|
        puts 'Needs fixing: ' + file
      end
    end

    def self.fix_site
      Nanoc::Application.ensure_in_site

      Dir["content/**/index.*"].each do |file|
        FileManager.rename_file(file, file.sub(/\/([^\/]+)\/index\./, '/\1/\1.'))
      end
    end

  end
end
