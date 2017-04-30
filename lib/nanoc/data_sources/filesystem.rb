module Nanoc::DataSources
  # The filesystem data source stores its items and layouts in nested
  # directories. Items and layouts are represented by one or two files; if it
  # is represented using one file, the metadata can be contained in this file.
  #
  # The default root directory for items is the `content` directory; for
  # layouts, this is the `layouts` directory. This can be overridden
  # in the data source configuration:
  #
  #     data_sources:
  #       - type:         filesystem
  #         content_dir:  items
  #         layouts_dir:  layouts
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
  # The identifier of items and layouts is the filename itself, without the
  # root directory (as determined by the `content_dir` or `layouts_dir`
  # configuration attribute, for items resp. layouts). For example:
  #
  #     foo/bar/index.html → /foo/bar/index.html
  #     foo/bar.html       → /foo/bar.html
  #
  # Note that each item must have an unique identifier. Nanoc will display an
  # error if two items with the same identifier are found.
  #
  # The file extension does not determine the filters to run on items; the
  # Rules file is used to specify processing instructors for each item.
  #
  # It is possible to set an explicit encoding that should be used when reading
  # files. In the data source configuration, set `encoding` to an encoding
  # understood by Ruby’s `Encoding`. If no encoding is set in the configuration,
  # one will be inferred from the environment.
  #
  # @api private
  class Filesystem < Nanoc::DataSource
    identifiers :filesystem, :filesystem_unified

    # See {Nanoc::DataSource#up}.
    def up; end

    # See {Nanoc::DataSource#down}.
    def down; end

    def content_dir_name
      config.fetch(:content_dir, 'content')
    end

    def layouts_dir_name
      config.fetch(:layouts_dir, 'layouts')
    end

    # See {Nanoc::DataSource#items}.
    def items
      load_objects(content_dir_name, Nanoc::Int::Item)
    end

    # See {Nanoc::DataSource#layouts}.
    def layouts
      load_objects(layouts_dir_name, Nanoc::Int::Layout)
    end

    protected

    class ProtoDocument
      attr_reader :attributes
      attr_reader :content_checksum_data
      attr_reader :attributes_checksum_data
      attr_reader :is_binary
      alias binary? is_binary

      def initialize(is_binary:, content: nil, filename: nil, attributes:, content_checksum_data: nil, attributes_checksum_data: nil)
        if content.nil? && filename.nil?
          raise ArgumentError, '#initialize needs at least content or filename'
        end

        @is_binary = is_binary
        @content = content
        @filename = filename
        @attributes = attributes
        @content_checksum_data = content_checksum_data
        @attributes_checksum_data = attributes_checksum_data
      end

      def content
        if binary?
          raise ArgumentError, 'cannot fetch content of binary item'
        else
          @content
        end
      end

      def filename
        if binary?
          @filename
        else
          raise ArgumentError, 'cannot fetch filename of non-binary item'
        end
      end
    end

    def read_proto_document(content_filename, meta_filename, klass)
      is_binary = content_filename && !@site_config[:text_extensions].include?(File.extname(content_filename)[1..-1])

      if is_binary && klass == Nanoc::Int::Item
        meta = (meta_filename && YAML.load_file(meta_filename)) || {}

        ProtoDocument.new(is_binary: true, filename: content_filename, attributes: meta)
      elsif is_binary && klass == Nanoc::Int::Layout
        raise Errors::BinaryLayout.new(content_filename)
      else
        parse_result = parse(content_filename, meta_filename)

        ProtoDocument.new(
          is_binary: false,
          content: parse_result.content,
          attributes: parse_result.attributes,
          content_checksum_data: parse_result.content,
          attributes_checksum_data: parse_result.attributes_data,
        )
      end
    end

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
    def load_objects(dir_name, klass)
      res = []

      return [] if dir_name.nil?

      all_split_files_in(dir_name).each do |base_filename, (meta_ext, content_exts)|
        content_exts.each do |content_ext|
          meta_filename    = filename_for(base_filename, meta_ext)
          content_filename = filename_for(base_filename, content_ext)

          proto_doc = read_proto_document(content_filename, meta_filename, klass)

          content = content_for(proto_doc, content_filename)
          attributes = attributes_for(proto_doc, content_filename, meta_filename)
          identifier = identifier_for(content_filename, meta_filename, dir_name)

          res << klass.new(
            content,
            attributes,
            identifier,
            content_checksum_data: content_checksum_data_for(proto_doc),
            attributes_checksum_data: attributes_checksum_data_for(proto_doc, content_filename, meta_filename),
          )
        end
      end

      res
    end

    def content_checksum_data_for(proto_doc)
      Digest::SHA1.digest(
        proto_doc.content_checksum_data || '',
      )
    end

    def attributes_checksum_data_for(proto_doc, content_filename, meta_filename)
      Digest::SHA1.digest(
        YAML.dump(
          attributes: proto_doc.attributes_checksum_data,
          extra_attributes: extra_attributes_for(content_filename, meta_filename),
        ),
      )
    end

    def extra_attributes_for(content_filename, meta_filename)
      {
        filename: content_filename,
        content_filename: content_filename,
        meta_filename: meta_filename,
        extension: content_filename ? ext_of(content_filename)[1..-1] : nil,
        mtime: mtime_of(content_filename, meta_filename),
      }
    end

    def attributes_for(proto_doc, content_filename, meta_filename)
      extra_attributes_for(content_filename, meta_filename).merge(proto_doc.attributes)
    end

    def identifier_for(content_filename, meta_filename, dir_name)
      if content_filename
        identifier_for_filename(content_filename[dir_name.length..-1])
      elsif meta_filename
        identifier_for_filename(meta_filename[dir_name.length..-1])
      else
        raise 'meta_filename and content_filename are both nil'
      end
    end

    def content_for(proto_doc, content_filename)
      full_content_filename = content_filename && File.expand_path(content_filename)

      if proto_doc.binary?
        Nanoc::Int::BinaryContent.new(full_content_filename)
      else
        Nanoc::Int::TextualContent.new(proto_doc.content, filename: full_content_filename)
      end
    end

    def mtime_of(content_filename, meta_filename)
      meta_mtime = meta_filename ? File.stat(meta_filename).mtime : nil
      content_mtime = content_filename ? File.stat(content_filename).mtime : nil
      if meta_mtime && content_mtime
        meta_mtime > content_mtime ? meta_mtime : content_mtime
      elsif meta_mtime
        meta_mtime
      elsif content_mtime
        content_mtime
      else
        raise 'meta_mtime and content_mtime are both nil'
      end
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
        content_filenames = filenames.reject { |fn| ext_of(fn) == '.yaml' }

        # Check number of files per type
        unless [0, 1].include?(meta_filenames.size)
          raise Errors::MultipleMetaFiles.new(meta_filenames, basename)
        end
        unless config[:identifier_type] == 'full'
          unless [0, 1].include?(content_filenames.size)
            raise Errors::MultipleContentFiles.new(meta_filenames, basename)
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
      Nanoc::DataSources::Filesystem::Tools.all_files_in(dir_name, config[:extra_files])
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
    def filename_for(base_filename, ext)
      if ext.nil?
        nil
      elsif ext.empty?
        base_filename
      else
        base_filename + '.' + ext
      end
    end

    # Returns the identifier that corresponds with the given filename, which
    # can be the content filename or the meta filename.
    def identifier_for_filename(filename)
      if config[:identifier_type] == 'full'
        return Nanoc::Identifier.new(filename)
      end

      regex =
        if filename =~ /(^|\/)index(\.[^\/]+)?$/
          allow_periods_in_identifiers? ? /\/?(index)?(\.[^\/\.]+)?$/ : /\/?index(\.[^\/]+)?$/
        else
          allow_periods_in_identifiers? ? /\.[^\/\.]+$/ : /\.[^\/]+$/
        end
      Nanoc::Identifier.new(filename.sub(regex, ''), type: :legacy)
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
      filename =~ extension_regex ? Regexp.last_match[1] : ''
    end

    # Returns a regex that is used for determining the extension of a file
    # name. The first match group will be the entire extension, including the
    # leading period.
    #
    # @return [Regex]
    def extension_regex
      if allow_periods_in_identifiers?
        /(\.[^\/\.]+$)/
      else
        /(\.[^\/]+$)/
      end
    end

    def allow_periods_in_identifiers?
      if @config
        @config[:allow_periods_in_identifiers] || @config[:identifier_type] == 'full'
      else
        false
      end
    end

    # @return [ParseResult]
    def parse(content_filename, meta_filename)
      if meta_filename
        parse_with_separate_meta_filename(content_filename, meta_filename)
      else
        parse_with_frontmatter(content_filename)
      end
    end

    # @return [ParseResult]
    def parse_with_separate_meta_filename(content_filename, meta_filename)
      content = content_filename ? read(content_filename) : ''
      meta_raw = read(meta_filename)
      meta = parse_metadata(meta_raw, meta_filename)
      ParseResult.new(content: content, attributes: meta, attributes_data: meta_raw)
    end

    # @return [ParseResult]
    def parse_with_frontmatter(content_filename)
      data = read(content_filename)

      if data !~ /\A-{3,5}\s*$/
        return ParseResult.new(content: data, attributes: {}, attributes_data: '')
      end

      pieces = data.split(/^(-{5}|-{3})[ \t]*\r?\n?/, 3)
      if pieces.size < 4
        raise Errors::InvalidFormat.new(content_filename)
      end

      meta = parse_metadata(pieces[2], content_filename)
      content = pieces[4]

      ParseResult.new(content: content, attributes: meta, attributes_data: pieces[2])
    end

    # @return [Hash]
    def parse_metadata(data, filename)
      begin
        meta = YAML.load(data) || {}
      rescue => e
        raise Errors::UnparseableMetadata.new(filename, e)
      end

      verify_meta(meta, filename)

      meta
    end

    class ParseResult
      attr_reader :content
      attr_reader :attributes
      attr_reader :attributes_data

      def initialize(content:, attributes:, attributes_data:)
        @content = content
        @attributes = attributes
        @attributes_data = attributes_data
      end
    end

    def verify_meta(meta, filename)
      return if meta.is_a?(Hash)

      raise Errors::InvalidMetadata.new(filename, meta.class)
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
        raise Errors::FileUnreadable.new(filename, e)
      end

      # Set original encoding, if any
      if @config && @config[:encoding]
        original_encoding = Encoding.find(@config[:encoding])
        data.force_encoding(@config[:encoding])
      else
        original_encoding = data.encoding
      end

      # Set encoding to UTF-8
      begin
        data.encode!('UTF-8')
      rescue
        raise Errors::InvalidEncoding.new(filename, original_encoding)
      end

      # Verify
      unless data.valid_encoding?
        raise Errors::InvalidEncoding.new(filename, original_encoding)
      end

      # Remove UTF-8 BOM (ugly)
      data.delete!("\xEF\xBB\xBF")

      data
    end
  end
end

require_relative 'filesystem/tools'
require_relative 'filesystem/errors'
