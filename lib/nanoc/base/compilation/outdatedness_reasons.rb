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

    NotEnoughData = Generic.new(
      'Not enough data is present to correctly determine whether the item is outdated.',
      Props.new(raw_content: true, attributes: true, compiled_content: true, path: true),
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
      Props.new(raw_content: true, compiled_content: true, path: true),
    )

    AttributesModified = Generic.new(
      'The attributes of this item have been modified since the last time the site was compiled.',
      Props.new(attributes: true, compiled_content: true, path: true),
    )
  end
end
