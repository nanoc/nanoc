# frozen_string_literal: true

# @api private
class Nanoc::DataSources::Filesystem
  class Parser
    SEPARATOR = /(-{5}|-{3})/.source

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

    def initialize(config:)
      @config = config
    end

    # @return [ParseResult]
    def call(content_filename, meta_filename)
      if meta_filename
        parse_with_separate_meta_filename(content_filename, meta_filename)
      else
        parse_with_frontmatter(content_filename)
      end
    end

    # @return [ParseResult]
    def parse_with_separate_meta_filename(content_filename, meta_filename)
      content = content_filename ? Tools.read_file(content_filename, config: @config) : ''
      meta_raw = Tools.read_file(meta_filename, config: @config)
      meta = parse_metadata(meta_raw, meta_filename)
      ParseResult.new(content:, attributes: meta, attributes_data: meta_raw)
    end

    # @return [ParseResult]
    def parse_with_frontmatter(content_filename)
      data = Tools.read_file(content_filename, config: @config)

      unless /\A#{SEPARATOR}\s*$/.match?(data)
        return ParseResult.new(content: data, attributes: {}, attributes_data: '')
      end

      pieces = data.split(/^#{SEPARATOR}[ \t]*\r?\n?/, 3)
      if pieces.size < 4
        raise Errors::InvalidFormat.new(content_filename)
      end

      meta = parse_metadata(pieces[2], content_filename)
      content = pieces[4].sub(/\A\n/, '')

      ParseResult.new(content:, attributes: meta, attributes_data: pieces[2])
    end

    # @return [Hash]
    def parse_metadata(data, filename)
      begin
        meta = Nanoc::Core::YamlLoader.load(data) || {}
      rescue => e
        raise Errors::UnparseableMetadata.new(filename, e)
      end

      verify_meta(meta, filename)

      meta
    end

    def frontmatter?(filename)
      data = Tools.read_file(filename, config: @config)
      /\A#{SEPARATOR}\s*$/.match?(data)
    end

    def verify_meta(meta, filename)
      return if meta.is_a?(Hash)

      raise Errors::InvalidMetadata.new(filename, meta.class)
    end
  end
end
