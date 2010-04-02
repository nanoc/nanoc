# encoding: utf-8

module Nanoc3

  # Module that contains all nanoc-specific errors.
  module Errors

    # Generic error. Superclass for all nanoc-specific errors.
    class Generic < ::StandardError
    end

    # Error that is raised when a site is loaded that uses a data source with
    # an unknown identifier.
    class UnknownDataSource < Generic

      # @param [String] data_source_name The data source name for which no
      # data source could be found
      def initialize(data_source_name)
        super("The data source specified in the site’s configuration file, “#{data_source_name}”, does not exist.".make_compatible_with_env)
      end

    end

    # Error that is raised during site compilation when an item uses a layout
    # that is not present in the site.
    class UnknownLayout < Generic

      # @param [String] layout_identifier The layout identifier for which no
      # layout could be found
      def initialize(layout_identifier)
        super("The site does not have a layout with identifier “#{layout_identifier}”.".make_compatible_with_env)
      end

    end

    # Error that is raised during site compilation when an item uses a filter
    # that is not known.
    class UnknownFilter < Generic

      # @param [Symbol] filter_name The filter name for which no filter could
      # be found
      def initialize(filter_name)
        super("The requested filter, “#{filter_name}”, does not exist.".make_compatible_with_env)
      end

    end

    # Error that is raised during site compilation when a layout is compiled
    # for which the filter cannot be determined. This is similar to the
    # {UnknownFilter} error, but specific for filters for layouts.
    class CannotDetermineFilter < Generic

      # @param [String] layout_identifier The identifier of the layout for
      # which the filter could not be determined
      def initialize(layout_identifier)
        super("The filter to be used for the “#{layout_identifier}” layout could not be determined. Make sure the layout does have a filter.".make_compatible_with_env)
      end

    end

    # Error that is raised when data is requested when the data is not yet
    # available (possibly due to a missing {Nanoc3::Site#load_data}).
    class DataNotYetAvailable < Generic

      # @param [String] type The name of the data type that is not yet
      # available. For example: `"site"`, `"items"`.
      #
      # @param [Boolean] plural True if the given type is plural, false
      # otherwise. This only has an effect on the exception message. For
      # example, if the given type is `"site"`, plural would be `false`; if
      # the given type is `"items"`, plural would be `true`.
      def initialize(type, plural)
        super("#{type} #{plural ? 'are' : 'is'} not available yet. You may be missing a Nanoc3::Site#load_data call.".make_compatible_with_env)
      end

    end

    # Error that is raised during site compilation when an item (directly or
    # indirectly) includes its own item content, leading to endless recursion.
    class RecursiveCompilation < Generic

      # @param [Array<Nanoc3::ItemRep>] reps A list of item representations
      # that mutually depend on each other
      def initialize(reps)
        super("The site cannot be compiled because the following items mutually depend on each other: #{reps.inspect}.".make_compatible_with_env)
      end

    end

    # Error that is raised when no rules file can be found in the current
    # working directory.
    class NoRulesFileFound < Generic

      def initialize
        super("This site does not have a rules file, which is required for nanoc sites.".make_compatible_with_env)
      end

    end

    # Error that is raised when no compilation rule that can be applied to the
    # current item can be found.
    class NoMatchingCompilationRuleFound < Generic

      # @param [Nanoc3::Item] item The item for which no compilation rule
      # could be found
      def initialize(item)
        super("No compilation rules were found for the “#{item.identifier}” item.".make_compatible_with_env)
      end

    end

    # Error that is raised when no routing rule that can be applied to the
    # current item can be found.
    class NoMatchingRoutingRuleFound < Generic

      # @param [Nanoc3::Item] item The item for which no routing rule could be
      # found
      def initialize(rep)
        super("No routing rules were found for the “#{rep.item.identifier}” item (rep “#{rep.name}”).".make_compatible_with_env)
      end

    end

    # Error that is raised when an rep cannot be compiled because it depends
    # on other representations.
    class UnmetDependency < Generic

      # @return [Nanoc3::ItemRep] The item representation that cannot yet be
      # compiled
      attr_reader :rep

      # @param [Nanoc3::ItemRep] The item representation that cannot yet be
      # compiled
      def initialize(rep)
        @rep = rep
        super("The current item cannot be compiled yet because of an unmet dependency on the “#{rep.item.identifier}” item (rep “#{rep.name}”).".make_compatible_with_env)
      end

    end

    # Error that is raised when a binary item is attempted to be laid out.
    class CannotLayoutBinaryItem < Generic

      # @param [Nanoc3::ItemRep] The item representation that was attempted to
      # be laid out
      def initialize(rep)
        super("The “{rep.item.identifier}” item (rep “#{rep.name}”) cannot be laid out because it is a binary item. If you are getting this error for an item that should be textual instead of binary, make sure that its extension is included in the text_extensions array in the site configuration.".make_compatible_with_env)
      end

    end

    # Error that is raised when a textual filter is attempted to be applied to
    # a binary item representation.
    class CannotUseTextualFilter < Generic

      # @param [Nanoc3::ItemRep] rep The item representation that was
      # attempted to be filtered
      #
      # @param [Class] filter_class The filter class that was used
      def initialize(rep, filter_class)
        super("The “#{filter_class.inspect}” filter cannot be used to filter the “#{rep.item.identifier}” item (rep “#{rep.name}”), because textual filters cannot be used on binary items.".make_compatible_with_env)
      end

    end

    # Error that is raised when a binary filter is attempted to be applied to
    # a textual item representation.
    class CannotUseBinaryFilter < Generic

      # @param [Nanoc3::ItemRep] rep The item representation that was
      # attempted to be filtered
      #
      # @param [Class] filter_class The filter class that was used
      def initialize(rep, filter_class)
        super("The “#{filter_class.inspect}” filter cannot be used to filter the “#{rep.item.identifier}” item (rep “#{rep.name}”), because binary filters cannot be used on textual items. If you are getting this error for an item that should be textual instead of binary, make sure that its extension is included in the text_extensions array in the site configuration.".make_compatible_with_env)
      end

    end

  end

end
