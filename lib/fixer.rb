module Nanoc
  class Fixer

    def self.check_site
      Nanoc::Application.ensure_in_site

      # Check for old-style index files
      Dir["content/**/index.*"].each do |file|
        puts 'Needs renaming: ' + file
      end

      # Check whether assets directory exists
      unless File.directory?('assets')
        puts 'Needs creating: assets'
      end
    end

    def self.fix_site
      Nanoc::Application.ensure_in_site

      # Move blah/index.* to blah/blah.*
      Dir["content/**/index.*"].each do |file|
        FileManager.rename_file(file, file.sub(/\/([^\/]+)\/index\./, '/\1/\1.'))
      end

      # Create assets directory if non-existant
      unless File.directory?('assets')
        FileMananger.create_dir 'assets'
      end
    end

  end
end
