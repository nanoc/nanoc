module Nanoc::Int
  # Module that contains all outdatedness reasons.
  #
  # @api private
  module OutdatednessReasons
    # A generic outdatedness reason. An outdatedness reason is basically a
    # descriptive message that explains why a given object is outdated.
    class Generic
      # @return [String] A descriptive message for this outdatedness reason
      attr_reader :message

      # @param [String] message The descriptive message for this outdatedness
      #   reason
      def initialize(message, raw_content: false, attributes: false, compiled_content: false, path: false)
        @message = message
        @raw_content = raw_content
        @attributes = attributes
        @compiled_content = compiled_content
        @path = path
      end

      def raw_content?
        @raw_content
      end

      def attributes?
        @attributes
      end

      def compiled_content?
        @compiled_content
      end

      def path?
        @path
      end

      def active_props
        Set.new.tap do |pr|
          pr << :raw_content if raw_content?
          pr << :attributes if attributes?
          pr << :compiled_content if compiled_content?
          pr << :path if path?
        end
      end
    end

    # TODO: specify props less conservatively

    CodeSnippetsModified = Generic.new(
      'The code snippets have been modified since the last time the site was compiled.',
      raw_content: true, attributes: true, compiled_content: true, path: true,
    )

    ConfigurationModified = Generic.new(
      'The site configuration has been modified since the last time the site was compiled.',
      raw_content: true, attributes: true, compiled_content: true, path: true,
    )

    DependenciesOutdated = Generic.new(
      'This item uses content or attributes that have changed since the last time the site was compiled.',
    )

    NotEnoughData = Generic.new(
      'Not enough data is present to correctly determine whether the item is outdated.',
      raw_content: true, attributes: true, compiled_content: true, path: true,
    )

    NotWritten = Generic.new(
      'This item representation has not yet been written to the output directory (but it does have a path).',
      raw_content: true, attributes: true, compiled_content: true, path: true,
    )

    RulesModified = Generic.new(
      'The rules file has been modified since the last time the site was compiled.',
      compiled_content: true, path: true,
    )

    ContentModified = Generic.new(
      'The content of this item has been modified since the last time the site was compiled.',
      raw_content: true, compiled_content: true, path: true,
    )

    AttributesModified = Generic.new(
      'The attributes of this item have been modified since the last time the site was compiled.',
      attributes: true, compiled_content: true, path: true,
    )
  end
end
