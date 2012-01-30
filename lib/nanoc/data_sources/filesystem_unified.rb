# encoding: utf-8

module Nanoc::DataSources

  # The filesystem_unified data source stores its items and layouts in nested
  # directories. Items and layouts are represented by one or two files; if it
  # is represented using one file, the metadata can be contained in this file.
  # The root directory for items is the `content` directory; for layouts, this
  # is the `layouts` directory.
  #
  # The metadata for items and layouts can be stored in a separate file with
  # the same base name but with the `.yaml` extension. If such a file is
  # found, metadata is read from that file. Alternatively, the content file
  # itself can start with a metadata section: it can be stored at the top of
  # the file, between `---` (three dashes) separators. For example:
  #
  #     ---
  #     title: "Moo!"
  #     ---
  #     h1. Hello!
  #
  # The metadata section can be omitted. If the file does not start with
  # three or five dashes, the entire file will be considered as content.
  #
  # The identifier of items and layouts is determined as follows. A file with
  # an `index.*` filename, such as `index.txt`, will have the filesystem path
  # with the `index.*` part stripped as a identifier. For example:
  #
  #     foo/bar/index.html → /foo/bar/
  #
  # In other cases, the identifier is calculated by stripping the extension.
  # If the `allow_periods_in_identifiers` attribute in the configuration is
  # true, only the last extension will be stripped if the file has multiple
  # extensions; if it is false or unset, all extensions will be stripped.
  # For example:
  #
  #     (`allow_periods_in_identifiers` set to true)
  #     foo.entry.html → /foo.entry/
  #     
  #     (`allow_periods_in_identifiers` set to false)
  #     foo.html.erb → /foo/
  #
  # Note that each item must have an unique identifier. nanoc will display an
  # error if two items with the same identifier are found.
  #
  # Some more examples:
  #
  #     content/index.html          → /
  #     content/foo.html            → /foo/
  #     content/foo/index.html      → /foo/
  #     content/foo/bar.html        → /foo/bar/
  #     content/foo/bar.baz.html    → /foo/bar/ OR /foo/bar.baz/
  #     content/foo/bar/index.html  → /foo/bar/
  #     content/foo.bar/index.html  → /foo.bar/
  #
  # The file extension does not determine the filters to run on items; the
  # Rules file is used to specify processing instructors for each item.
  #
  # It is possible to set an explicit encoding that should be used when reading
  # files. In the data source configuration, set `encoding` to an encoding
  # understood by Ruby’s `Encoding`. If no encoding is set in the configuration,
  # one will be inferred from the environment.
  class FilesystemUnified < Nanoc::DataSource

    include Nanoc::DataSources::Filesystem

  private

    # See {Nanoc::DataSources::Filesystem#create_object}.
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
      Nanoc::NotificationCenter.post(:file_created, path)

      # Write item
      FileUtils.mkdir_p(parent_path)
      File.open(path, 'w') do |io|
        meta = attributes.stringify_keys
        unless meta == {}
          io.write(YAML.dump(meta).strip + "\n")
          io.write("---\n\n")
        end
        io.write(content)
      end
    end

    # See {Nanoc::DataSources::Filesystem#filename_for}.
    def filename_for(base_filename, ext)
      if ext.nil?
        nil
      elsif ext.empty?
        base_filename
      else
        base_filename + '.' + ext
      end
    end

    # Returns the identifier derived from the given filename, first stripping
    # the given directory name off the filename.
    def identifier_for_filename(filename)
      if filename =~ /(^|\/)index\.[^\/]+$/
        regex = ((@config && @config[:allow_periods_in_identifiers]) ? /\/?index\.[^\/\.]+$/ : /\/?index\.[^\/]+$/)
      else
        regex = ((@config && @config[:allow_periods_in_identifiers]) ? /\.[^\/\.]+$/         : /\.[^\/]+$/)
      end
      filename.sub(regex, '').cleaned_identifier
    end

  end

end
