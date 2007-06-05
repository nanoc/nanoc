module Nanoc
  class Fixer

    def self.fix_site
      Nanoc::Application.ensure_in_site

      # Fix (very-)old-style content files
      # TODO use File::SEPARATOR where possible
      Dir["content/**/meta.yaml"].each do |filename|
        if filename == 'content/meta.yaml'
          FileManager.rename_file 'content/meta.yaml', 'content/index.yaml'
        else
          parent_dir_path = filename.sub(/\/meta\.yaml$/, '\1')
          parent_dir_name = filename.sub(/.*\/([^\/]+)\/meta\.yaml$/, '\1')
          files_new = Dir[parent_dir_path + '/' + parent_dir_name + '.*']
          files_old = Dir[parent_dir_path + '/index.*']
          is_old = !files_old.empty?
          files = files_old + files_new
          extension = files[0].sub(/.*\.([^\.\/]+)$/, '\1')
          old_name = parent_dir_path + '/' + (is_old ? 'index' : parent_dir_name) + '.' + extension
          new_name = parent_dir_path + '.' + extension
          FileManager.rename_file(filename, filename.sub(/\/meta\.yaml$/, '.yaml'))
          FileManager.rename_file(old_name, new_name)
        end
      end

      # Create assets directory if non-existant
      unless File.directory?('assets')
        FileManager.create_dir 'assets'
      end
    end

  end
end
