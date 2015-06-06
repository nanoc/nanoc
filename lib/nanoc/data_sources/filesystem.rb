module Nanoc::DataSources
  # Provides functionality common across all filesystem data sources.
  #
  # @api private
  module Filesystem
    # See {Nanoc::DataSource#up}.
    def up
    end

    # See {Nanoc::DataSource#down}.
    def down
    end

    def content_dir_name
      config.fetch(:content_dir, 'content')
    end

    def layouts_dir_name
      config.fetch(:layouts_dir, 'layouts')
    end

    # See {Nanoc::DataSource#items}.
    def items
      load_objects(content_dir_name, 'item', Nanoc::Int::Item)
    end

    # See {Nanoc::DataSource#layouts}.
    def layouts
      load_objects(layouts_dir_name, 'layout', Nanoc::Int::Layout)
    end

    protected

    # Creates instances of klass corresponding to the files in dir_name. The
    # kind attribute indicates the kind of object that is being loaded and is
    # used solely for debugging purposes.
    #
    # This particular implementation loads objects from a filesystem-based
    # data source where content and attributes can be spread over two separate
    # files. The content and meta-file are optional (but at least one of them
    # needs to be present, obviously) and the content file can start with a
    # metadata section.
    #
    # @see Nanoc::DataSources::Filesystem#load_objects
    def load_objects(dir_name, kind, klass)
      res = []

      return [] if dir_name.nil?

      all_split_files_in(dir_name).each do |base_filename, (meta_ext, content_exts)|
        content_exts.each do |content_ext|
          # Get filenames
          meta_filename    = filename_for(base_filename, meta_ext)
          content_filename = filename_for(base_filename, content_ext)

          # Read content and metadata
          is_binary = content_filename && !@site.config[:text_extensions].include?(File.extname(content_filename)[1..-1])
          if is_binary && klass == Nanoc::Int::Item
            meta                = (meta_filename && YAML.load_file(meta_filename)) || {}
            content_or_filename = content_filename
          elsif is_binary && klass == Nanoc::Int::Layout
            raise "The layout file '#{content_filename}' is a binary file, but layouts can only be textual"
          else
            meta, content_or_filename = parse(content_filename, meta_filename, kind)
          end

          # Get attributes
          attributes = {
            filename: content_filename,
            content_filename: content_filename,
            meta_filename: meta_filename,
            extension: content_filename ? ext_of(content_filename)[1..-1] : nil,
          }.merge(meta)

          # Get identifier
          if content_filename
            identifier = identifier_for_filename(content_filename[dir_name.length..-1])
          elsif meta_filename
            identifier = identifier_for_filename(meta_filename[dir_name.length..-1])
          else
            raise 'meta_filename and content_filename are both nil'
          end

          # Get modification times
          meta_mtime = meta_filename ? File.stat(meta_filename).mtime : nil
          content_mtime = content_filename ? File.stat(content_filename).mtime : nil
          if meta_mtime && content_mtime
            mtime = meta_mtime > content_mtime ? meta_mtime : content_mtime
          elsif meta_mtime
            mtime = meta_mtime
          elsif content_mtime
            mtime = content_mtime
          else
            raise 'meta_mtime and content_mtime are both nil'
          end
          attributes[:mtime] = mtime

          # Create content
          content =
            if is_binary
              Nanoc::Int::BinaryContent.new(content_or_filename)
            else
              Nanoc::Int::TextualContent.new(content_or_filename, filename: content_filename)
            end

          # Create object
          res << klass.new(content, attributes, identifier)
        end
      end

      res
    end

    # e.g.
    #
    #   {
    #     'content/foo' => [ 'yaml', ['html', 'md'] ],
    #     'content/bar' => [ 'yaml', [nil]          ],
    #     'content/qux' => [ nil,    ['html']       ]
    #   }
    def all_split_files_in(dir_name)
      by_basename =
        all_files_in(dir_name)
        .reject   { |fn| fn =~ /(~|\.orig|\.rej|\.bak)$/ }
        .group_by { |fn| basename_of(fn) }

      all = {}

      by_basename.each_pair do |basename, filenames|
        # Divide
        meta_filenames    = filenames.select { |fn| ext_of(fn) == '.yaml' }
        content_filenames = filenames.select { |fn| ext_of(fn) != '.yaml' }

        # Check number of files per type
        unless [0, 1].include?(meta_filenames.size)
          raise "Found #{meta_filenames.size} meta files for #{basename}; expected 0 or 1"
        end
        unless config[:identifier_type] == 'full'
          unless [0, 1].include?(content_filenames.size)
            raise "Found #{content_filenames.size} content files for #{basename}; expected 0 or 1"
          end
        end

        all[basename] = []
        all[basename][0] =
          meta_filenames[0] ? 'yaml' : nil
        all[basename][1] =
          content_filenames.any? ? content_filenames.map { |fn| ext_of(fn)[1..-1] || '' } : [nil]
      end

      all
    end

    # Returns all files in the given directory and directories below it.
    def all_files_in(dir_name)
      Nanoc::Extra::FilesystemTools.all_files_in(dir_name, config[:extra_files])
    end

    # Returns the filename for the given base filename and the extension.
    #
    # If the extension is nil, this function should return nil as well.
    #
    # A simple implementation would simply concatenate the base filename, a
    # period and an extension (which is what the
    # {Nanoc::DataSources::FilesystemCompact} data source does), but other
    # data sources may prefer to implement this differently (for example,
    # {Nanoc::DataSources::FilesystemVerbose} doubles the last part of the
    # basename before concatenating it with a period and the extension).
    def filename_for(_base_filename, _ext)
      raise NotImplementedError.new(
        "#{self.class} does not implement #filename_for"
      )
    end

    # Returns the identifier that corresponds with the given filename, which
    # can be the content filename or the meta filename.
    def identifier_for_filename(_filename)
      raise NotImplementedError.new(
        "#{self.class} does not implement #identifier_for_filename"
      )
    end

    # Returns the base name of filename, i.e. filename with the first or all
    # extensions stripped off. By default, all extensions are stripped off,
    # but when allow_periods_in_identifiers is set to true in the site
    # configuration, only the last extension will be stripped .
    def basename_of(filename)
      filename.sub(extension_regex, '')
    end

    # Returns the extension(s) of filename. Supports multiple extensions.
    # Includes the leading period.
    def ext_of(filename)
      filename =~ extension_regex ? $1 : ''
    end

    # Returns a regex that is used for determining the extension of a file
    # name. The first match group will be the entire extension, including the
    # leading period.
    def extension_regex
      if @config && @config[:allow_periods_in_identifiers]
        /(\.[^\/\.]+$)/
      else
        /(\.[^\/]+$)/
      end
    end

    # Parses the file named `filename` and returns an array with its first
    # element a hash with the file's metadata, and with its second element the
    # file content itself.
    def parse(content_filename, meta_filename, _kind)
      # Read content and metadata from separate files
      if meta_filename
        content = content_filename ? read(content_filename) : ''
        meta_raw = read(meta_filename)
        begin
          meta = YAML.load(meta_raw) || {}
        rescue Exception => e
          raise "Could not parse YAML for #{meta_filename}: #{e.message}"
        end
        return [meta, content]
      end

      # Read data
      data = read(content_filename)

      # Check presence of metadata section
      if data !~ /\A-{3,5}\s*$/
        return [{}, data]
      end

      # Split data
      pieces = data.split(/^(-{5}|-{3})[ \t]*\r?\n?/, 3)
      if pieces.size < 4
        raise RuntimeError.new(
          "The file '#{content_filename}' appears to start with a metadata section (three or five dashes at the top) but it does not seem to be in the correct format."
        )
      end

      # Parse
      begin
        meta = YAML.load(pieces[2]) || {}
      rescue Exception => e
        raise "Could not parse YAML for #{content_filename}: #{e.message}"
      end
      content = pieces[4]

      # Done
      [meta, content]
    end

    # Reads the content of the file with the given name and returns a string
    # in UTF-8 encoding. The original encoding of the string is derived from
    # the default external encoding, but this can be overridden by the
    # “encoding” configuration attribute in the data source configuration.
    def read(filename)
      # Read
      begin
        data = File.read(filename)
      rescue => e
        raise RuntimeError.new("Could not read #{filename}: #{e.inspect}")
      end

      # Fix
      if data.respond_to?(:encode!)
        if @config && @config[:encoding]
          original_encoding = Encoding.find(@config[:encoding])
          data.force_encoding(@config[:encoding])
        else
          original_encoding = data.encoding
        end

        begin
          data.encode!('UTF-8')
        rescue
          raise_encoding_error(filename, original_encoding)
        end

        unless data.valid_encoding?
          raise_encoding_error(filename, original_encoding)
        end
      end

      # Remove UTF-8 BOM (ugly)
      data.gsub!("\xEF\xBB\xBF", '')

      data
    end

    # Raises an invalid encoding error for the given filename and encoding.
    def raise_encoding_error(filename, encoding)
      raise RuntimeError.new("Could not read #{filename} because the file is not valid #{encoding}.")
    end
  end
end
