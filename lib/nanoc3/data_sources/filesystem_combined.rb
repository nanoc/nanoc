# encoding: utf-8

module Nanoc3::DataSources

  # The filesystem data source stores its items and layouts in nested
  # directories. Items and layouts are represented by single files. The root
  # directory for items is the `content` directory; for layouts, this is the
  # `layouts` directory.
  #
  # The metadata for items and layouts is embedded into the file itself. It is
  # stored at the top of the file, between `---` (three dashes) separators.
  # For example:
  #
  #     ---
  #     title: "Moo!"
  #     ---
  #     h1. Hello!
  #
  # The metadata section can be omitted. If the file does not start with
  # three or five dashes, the entire file will be considered as content; the
  # returned metadata will be empty.
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
  # Note that it is possible for two different, separate files to have the
  # same identifier. It is recommended to avoid such situations.
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
  class FilesystemCombined < Nanoc3::DataSources::Filesystem

  private

    # Finds all files in the given directory, ignoring any unwanted files.
    # Unwanted files are files that end with `~`, `.orig`, `.rej` or `.bak`.
    # This method will recurse into subdirectories.
    def files(dir)
      Dir[dir + '/**/*'].reject do |filename|
        File.directory?(filename) ||
          filename =~ /(~|\.orig|\.rej|\.bak)$/
      end
    end

    # Parses the file named `filename` and returns an array with its first
    # element a hash with the file's metadata, and with its second element the
    # file content itself.
    def parse_file(filename, kind)
      # Read
      content = File.read(filename)

      # Return metadataless content if there is no metadata section
      if content !~ /^(-{5}|-{3})/
        return [ {}, content ]
      end

      # Split file
      pieces = content.split(/^(-{5}|-{3})/).compact
      if pieces.size < 3
        raise RuntimeError.new(
          "The file '#{filename}' does not seem to be a nanoc #{kind}"
        )
      end

      # Parse
      meta    = YAML.load(pieces[2]) || {}
      content = pieces[4..-1].join.strip

      # Done
      [ meta, content ]
    end

    # See {Nanoc3::DataSources::Filesystem#create_object}.
    def create_object(dir_name, content, attributes, identifier)
      # Determine path
      path = dir_name + (identifier == '/' ? '/index.html' : identifier[0..-2] + '.html')
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
      files(dir_name).map do |filename|
        # Read and parse data
        meta, content = *parse_file(filename, kind)

        # Get attributes
        attributes = {
          :filename  => filename,
          :extension => File.extname(filename)[1..-1],
          :file      => Nanoc3::Extra::FileProxy.new(filename)
        }.merge(meta)

        # Get actual identifier
        identifier = filename_to_identifier(filename, dir_name)

        # Get mtime
        mtime = File.stat(filename).mtime

        # Build item
        klass.new(content, attributes, identifier, mtime)
      end
    end

    # Returns the identifier derived from the given filename, first stripping
    # the given directory name off the filename.
    def filename_to_identifier(filename, dir_name)
      # Get actual identifier
      identifier = filename.sub(Regexp.new("^#{dir_name}"), '')
      if filename =~ /\/index\.[^\/]+$/
        regex = ((@config && @config[:allow_periods_in_identifiers]) ? /index\.[^\/\.]+$/ : /index\.[^\/]+$/)
      else
        regex = ((@config && @config[:allow_periods_in_identifiers]) ? /\.[^\/\.]+$/      : /\.[^\/]+$/)
      end
      identifier.sub(regex, '') + '/'
    end

  end

end
