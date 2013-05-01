# encoding: utf-8

module Nanoc::DataSources

  # The filesystem data source stores its items and layouts in nested
  # directories. Items and layouts are represented by one or two files; if it
  # is represented using one file, the attributes can be contained in this file.
  # The root directory for items is the `content` directory; for layouts, this
  # is the `layouts` directory.
  #
  # The attributes for items and layouts can be stored in two ways:
  #
  # * The attributes can be stored in a separate file with the same filename as
  #   the content file, followed by '.yaml'. For example, the attributes file
  #   for a content file called "foo.md" would be "foo.md.yaml".
  #
  # * The content file itself can start with an attributes section. The
  #   attributes section can be found at the top of the file, before any
  #   content, between `---` (three dashes) separators. For example:
  #
  #       ---
  #       title: "Moo!"
  #       ---
  #       h1. Hello!
  #
  # The identifier of items and layouts is the filename itself, relative to the
  # `content` or `layout` directory and starting with a slash.
  #
  # This data source has the following configuration options:
  #
  # * `encoding` - the character encoding that should be used when reading
  #   files. Defaults to UTF-8.
  #
  # * `text_extensions` - a list of filename extensions that should be treated
  #   as textual items.
  class Filesystem < Nanoc::DataSource

    identifier :filesystem

    # See {Nanoc::DataSource#setup}.
    def setup
      # Create directories
      %w( content layouts ).each do |dir|
        FileUtils.mkdir_p(dir)
      end
    end

    # See {Nanoc::DataSource#items}.
    def items
      load_objects('content', 'item', Nanoc::Item)
    end

    # See {Nanoc::DataSource#layouts}.
    def layouts
      load_objects('layouts', 'layout', Nanoc::Layout)
    end

    # See {Nanoc::DataSource#create_item}.
    def create_item(content, attributes, identifier, params={})
      create_object('content', content, attributes, identifier, params)
    end

    # See {Nanoc::DataSource#create_layout}.
    def create_layout(content, attributes, identifier, params={})
      create_object('layouts', content, attributes, identifier, params)
    end

    # Creates a new object (item or layout) on disk in dir_name according to
    # the given identifier. The file will have its attributes taken from the
    # attributes hash argument and its content from the content argument.
    #
    # @api private
    def create_object(dir_name, content, attributes, identifier, params={})
      # Determine path
      ext = params[:extension] || '.html'
      path = dir_name + (identifier == '/' ? '/index.html' : identifier[0..-2] + ext)
      parent_path = File.dirname(path)

      # Notify
      Nanoc::NotificationCenter.post(:file_created, path)

      # Write object
      FileUtils.mkdir_p(parent_path)
      File.open(path, 'w') do |io|
        unless attributes == {}
          attributes = attributes.stringify_keys_recursively
          io.write(YAML.dump(attributes).strip + "\n")
          io.write("---\n\n")
        end
        io.write(content)
      end
    end

    # @param [String] extension The extension to check binary-ness for
    #
    # @return [Boolean] true if the given extension is binary, false otherwise
    #
    # @api private
    def binary_extension?(extension)
      !@site.config[:text_extensions].include?(extension)
    end

    # Creates instances of klass corresponding to the files in dir_name. The
    # kind attribute indicates the kind of object that is being loaded and is
    # used solely for debugging purposes.
    #
    # @api private
    def load_objects(dir_name, kind, klass)
      self.all_base_filenames_in(dir_name).map do |base_filename|
        # Determine filenames
        content_filename    = base_filename
        attributes_filename = base_filename + '.yaml'

        # Determine existence
        has_content_file    = File.exist?(content_filename)
        has_attributes_file = File.exist?(attributes_filename)

        # Read content and filename
        if has_attributes_file
          attributes = YAML.load_file(attributes_filename)
        else
          attributes = {} # can be overridden later
        end
        if has_content_file
          # Extract extension
          # Note that File.extname returns ".xyz" but we want "xyz".
          # Also note that if the given filename has no extension, "" is returned.
          extension = File.extname(base_filename)[1..-1]
          extension = nil if extension == ''

          # Is binary?
          is_binary = extension && self.binary_extension?(extension)

          if is_binary
            content_or_filename = content_filename
          else
            if has_attributes_file
              content_or_filename = self.read(content_filename)
            else
              content_or_filename, attributes = self.content_and_attributes_for_data(self.read(content_filename))
            end
          end
        end

        # Get identifier
        # TODO make base dir name configurable
        identifier = base_filename.sub(/^(content|layouts)\//, '/')

        # Create layout object
        # TODO maybe pass a Pathname to signify binary-ness?
        obj = klass.new(content_or_filename, attributes, identifier, :binary => is_binary)
        obj.raw_filename = content_filename
        obj
      end
    end

    # Finds all base filenames, i.e. all filenames except attribute filenames,
    # in the given directory.
    #
    # @param [String] dir_name The name of the directory to find all base filenames in
    #
    # @return [<String>] A collection of base filenames
    #
    # @api private
    def all_base_filenames_in(dir_name)
      self.all_files_in(dir_name).
        reject { |fn| fn =~ /(~|\.orig|\.rej|\.bak)$/ }.
        map    { |fn| fn.sub(/\.yaml$/, '') }.
        uniq
    end

    # Returns all files in the given directory and directories below it.
    #
    # @api private
    def all_files_in(dir_name)
      Nanoc::Extra::FilesystemTools.all_files_in(dir_name)
    end

    # @param [String] data Data including an attributes and a content section
    #
    # @return [Array] A tuple containing an attributes hash as its first
    #   element, and a string containing the content as its second element
    #
    # @api private
    def content_and_attributes_for_data(data)
      # Check presence of attributes section
      if data !~ /\A---\s*$/
        return [ data, {} ]
      end

      # Split data
      pieces = data.split(/^---\s*$\n/)
      if pieces.size < 3
        # TODO re-add filename to this exception
        raise RuntimeError.new(
          "The file appears to start with an attributes " +
          "section (three dashes at the top), but it does not seem to be " +
          "in the correct format."
        )
      end

      # Parse
      begin
        attributes = YAML.load(pieces[1]) || {}
      rescue Exception => e
        raise "Could not parse YAML in #{base_filename}: #{e.message}"
      end
      content = pieces[2..-1].join.strip

      # Done
      [ content, attributes ]
    end

    # Reads the content of the file with the given name and returns a string
    # in UTF-8 encoding. The original encoding of the string is derived from
    # the default external encoding, but this can be overridden by the
    # “encoding” configuration attribute in the data source configuration.
    #
    # @api private
    def read(filename)
      # Read
      begin
        data = File.binread(filename)
      rescue => e
        raise RuntimeError.new("Could not read #{filename}: #{e.inspect}")
      end

      # Re-encode
      encoding = (@config && @config[:encoding]) || 'utf-8'
      data.force_encoding(encoding)
      data.encode!('utf-8')

      # Remove UTF-8 BOM
      data.gsub!("\xEF\xBB\xBF", '')

      data
    end

    # Raises an invalid encoding error for the given filename and encoding.
    #
    # @api private
    def raise_encoding_error(filename, encoding)
      raise RuntimeError.new("Could not read #{filename} because the file is not valid #{encoding}.")
    end

  end

end
