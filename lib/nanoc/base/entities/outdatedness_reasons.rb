# frozen_string_literal: true

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

      # @return [Nanoc::Int::Props]
      attr_reader :props

      # @param [String] message The descriptive message for this outdatedness
      #   reason
      def initialize(message, props = Nanoc::Int::Props.new)
        @message = message
        @props = props
      end
    end

    CodeSnippetsModified = Generic.new(
      'The code snippets have been modified since the last time the site was compiled.',
      Props.new(raw_content: true, attributes: true, compiled_content: true, path: true),
    )

    ConfigurationModified = Generic.new(
      'The site configuration has been modified since the last time the site was compiled.',
      Props.new(raw_content: true, attributes: true, compiled_content: true, path: true),
    )

    DependenciesOutdated = Generic.new(
      'This item uses content or attributes that have changed since the last time the site was compiled.',
    )

    NotWritten = Generic.new(
      'This item representation has not yet been written to the output directory (but it does have a path).',
      Props.new(raw_content: true, attributes: true, compiled_content: true, path: true),
    )

    RulesModified = Generic.new(
      'The rules file has been modified since the last time the site was compiled.',
      Props.new(compiled_content: true, path: true),
    )

    ContentModified = Generic.new(
      'The content of this item has been modified since the last time the site was compiled.',
      Props.new(raw_content: true, compiled_content: true),
    )

    class AttributesModified < Generic
      attr_reader :attributes

      def initialize(attributes)
        super(
          'The attributes of this item have been modified since the last time the site was compiled.',
          Props.new(attributes: true, compiled_content: true),
        )

        @attributes = attributes
      end
    end

    UsesAlwaysOutdatedFilter = Generic.new(
      'This item rep uses one or more filters that cannot track dependencies, and will thus always be considered as outdated.',
      Props.new(raw_content: true, attributes: true, compiled_content: true),
    )
  end
end
