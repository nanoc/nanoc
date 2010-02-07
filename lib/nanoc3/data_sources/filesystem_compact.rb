# encoding: utf-8

module Nanoc3::DataSources

  # Items and layouts are stored as pairs of two files: a content file,
  # containing the actual item/layout content, and a meta file, containing the
  # item/layout's attributes, formatted as YAML. The content file and the
  # corresponding meta file have the same filename but not the same extension;
  # the meta file's extension is `.yaml` and the extension of the content file
  # can be freely chosen.
  #
  # Items are stored in the `content` directory of the nanoc site, while
  # layouts are stored in the `layouts` directory.
  #
  # The identifier of a item or layout is determined as follows. A file with
  # an `index.*` content filename, such as `index.txt`, will have the
  # filesystem path with the 'index.*' part stripped as a identifier. For
  # example:
  #
  #     foo/bar/index.html → /foo/bar/
  #
  # In other cases, the identifier is calculated by stripping the extension.
  # If the `allow_periods_in_identifiers` attribute in the configuration is
  # true, only the last extension will be stripped if the file has multiple
  # extensions; if it is false or unset, all extensions will be stripped.
  # For example:
  #
  #     (allow_periods_in_identifiers set to true)
  #     foo.entry.html → /foo.entry/
  #     
  #     (allow_periods_in_identifiers set to false)
  #     foo.html.erb → /foo/
  #
  # Note that it is possible for two different, separate files to have the
  # same identifier. It is recommended to avoid such situations.
  #
  # For example, this directory structure:
  #
  #     content/
  #       index.html
  #       index.yaml
  #       about.html
  #       about.yaml
  #       journal.html
  #       journal.yaml
  #       journal/
  #         2005.html
  #         2005.yaml
  #         2005/
  #           a-very-old-post.html
  #           a-very-old-post.yaml
  #           another-very-old-post.html
  #           another-very-old-post.yaml
  #           foo.entry.html
  #           foo.entry.yaml
  #       myst/
  #         index.html
  #         index.yaml
  #
  # … corresponds with the following items:
  #
  #     /
  #     /about/
  #     /journal/
  #     /journal/2005/
  #     /journal/2005/a-very-old-post/
  #     /journal/2005/another-very-old-post/
  #     /journal/2005/foo.entry/ OR /journal/2005/foo/
  #     /myst/
  class FilesystemCompact < Nanoc3::DataSource

    include Nanoc3::DataSources::Filesystem

  private

    # See {Nanoc3::DataSources::Filesystem#create_object}.
    def create_object(dir_name, content, attributes, identifier)
      # Check for periods
      if (@config.nil? || !@config[:allow_periods_in_identifiers]) && identifier.include?('.')
        raise RuntimeError,
          "Attempted to create an object in #{dir_name} with identifier #{identifier} containing a period, but allow_periods_in_identifiers is not enabled in the site configuration. (Enabling allow_periods_in_identifiers may cause the site to break, though.)"
      end

      # Get filenames
      base_path = dir_name + (identifier == '/' ? '/index' : identifier[0..-2])
      meta_filename    = base_path + '.yaml'
      content_filename = base_path + '.html'

      # Notify
      Nanoc3::NotificationCenter.post(:file_created, meta_filename)
      Nanoc3::NotificationCenter.post(:file_created, content_filename)

      # Create files
      FileUtils.mkdir_p(File.dirname(meta_filename))
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(content) }
    end

    # See {Nanoc3::DataSources::Filesystem#load_objects}.
    def load_objects(dir_name, kind, klass)
      load_split_objects(dir_name, kind, klass)
    end

    # See {Nanoc3::DataSources::Filesystem#filename_for}.
    def filename_for(base_filename, ext)
      ext ? base_filename + '.' + ext : nil
    end

    # Returns the identifier for the given filename. This method assumes that
    # the base is already stripped.
    #
    # For example:
    #
    #     /foo.yaml           -> /foo/
    #     /foo/index.yaml     -> /foo/
    #     /foo/index.erb      -> /foo/
    #     /foo/foo.yaml       -> /foo/foo/
    #     /foo/bar.html       -> /foo/bar/
    #     /foo/bar.entry.yaml -> /foo/bar.entry/
    def identifier_for_filename(filename)
      basename_of(filename).sub(/index$/, '').cleaned_identifier
    end

  end

end
