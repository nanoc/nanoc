# encoding: utf-8

module Nanoc3::DataSources

  # TODO document
  class FilesystemUnified < Nanoc3::DataSource

    include Nanoc3::DataSources::Filesystem

  private

    # See {Nanoc3::DataSources::Filesystem#create_object}.
    def create_object(dir_name, content, attributes, identifier, params={})
      # Check for periods
      if (@config.nil? || !@config[:allow_periods_in_identifiers]) && identifier.include?('.')
        raise RuntimeError,
          "Attempted to create an object in #{dir_name} with identifier #{identifier} containing a period, but allow_periods_in_identifiers is not enabled in the site configuration. (Enabling allow_periods_in_identifiers may cause the site to break, though.)"
      end

      # Determine path
      ext = params[:extension] || '.html'
      path = dir_name + (identifier == '/' ? '/index.html' : identifier[0..-2] + ext)
      parent_path = File.dirname(path)

      # Notify
      Nanoc3::NotificationCenter.post(:file_created, path)

      # Write item
      FileUtils.mkdir_p(parent_path)
      File.open(path, 'w') do |io|
        io.write(YAML.dump(attributes.stringify_keys) + "\n")
        io.write("---\n")
        io.write(content)
      end
    end

    # See {Nanoc3::DataSources::Filesystem#load_objects}.
    def load_objects(dir_name, kind, klass)
      load_split_objects(dir_name, kind, klass)
    end

    # See {Nanoc3::DataSources::Filesystem#filename_for}.
    def filename_for(base_filename, ext)
      ext ? base_filename + '.' + ext : nil
    end

    # Returns the identifier derived from the given filename, first stripping
    # the given directory name off the filename.
    def identifier_for_filename(filename)
      if filename =~ /index\.[^\/]+$/
        regex = ((@config && @config[:allow_periods_in_identifiers]) ? /index\.[^\/\.]+$/ : /index\.[^\/]+$/)
      else
        regex = ((@config && @config[:allow_periods_in_identifiers]) ? /\.[^\/\.]+$/      : /\.[^\/]+$/)
      end
      filename.sub(regex, '').cleaned_identifier
    end

  end

end
