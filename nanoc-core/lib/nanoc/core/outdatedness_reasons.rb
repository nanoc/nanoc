# frozen_string_literal: true

module Nanoc
  module Core
    # Module that contains all outdatedness reasons.
    #
    # @api private
    module OutdatednessReasons
      # A generic outdatedness reason. An outdatedness reason is basically a
      # descriptive message that explains why a given object is outdated.
      class Generic
        # @return [String] A descriptive message for this outdatedness reason
        attr_reader :message

        # @return [Nanoc::Core::DependencyProps]
        attr_reader :props

        # @param [String] message The descriptive message for this outdatedness
        #   reason
        def initialize(message, props = Nanoc::Core::DependencyProps.new)
          # TODO: Replace `DependencyProps` with its own `OutdatednessProps`
          # type. For `OutdatednessProps`, the only values are true/false;
          # giving a collection for `raw_content` makes no sense (anymore).

          @message = message
          @props = props
        end
      end

      CodeSnippetsModified = Generic.new(
        'The code snippets have been modified since the last time the site was compiled.',
        Nanoc::Core::DependencyProps.new(raw_content: true, attributes: true, compiled_content: true, path: true),
      )

      DependenciesOutdated = Generic.new(
        'This item uses content or attributes that have changed since the last time the site was compiled.',
      )

      NotWritten = Generic.new(
        'This item representation has not yet been written to the output directory (but it does have a path).',
        Nanoc::Core::DependencyProps.new(raw_content: true, attributes: true, compiled_content: true, path: true),
      )

      RulesModified = Generic.new(
        'The rules file has been modified since the last time the site was compiled.',
        Nanoc::Core::DependencyProps.new(compiled_content: true, path: true),
      )

      DocumentAdded = Generic.new(
        'The item or layout is newly added to the site.',
        Nanoc::Core::DependencyProps.new, # NOTE: empty props, because they’re not relevant
      )

      ContentModified = Generic.new(
        'The content of this item has been modified since the last time the site was compiled.',
        Nanoc::Core::DependencyProps.new(raw_content: true, compiled_content: true),
      )

      class AttributesModified < Generic
        attr_reader :attributes

        def initialize(attributes)
          super(
            'The attributes of this item have been modified since the last time the site was compiled.',
            Nanoc::Core::DependencyProps.new(attributes: true, compiled_content: true),
          )

          @attributes = attributes
        end
      end

      UsesAlwaysOutdatedFilter = Generic.new(
        'This item rep uses one or more filters that cannot track dependencies, and will thus always be considered as outdated.',
        Nanoc::Core::DependencyProps.new(raw_content: true, attributes: true, compiled_content: true),
      )
    end
  end
end
