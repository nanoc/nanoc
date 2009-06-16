# encoding: utf-8

module Nanoc3

  module Errors

    # Generic error. Superclass for all nanoc-specific errors.
    class Generic < ::StandardError
    end

    # Error that is raised when a site is loaded that uses a data source with
    # an unknown identifier.
    class UnknownDataSource < Generic
      def initialize(data_source_name)
        super("The data source specified in the site's configuration file, #{data_source_name}, does not exist.")
      end
    end

    # Error that is raised during site compilation when an item uses a layout
    # that is not present in the site.
    class UnknownLayout < Generic
      def initialize(layout_identifier)
        super("The site does not have a layout with identifier '#{layout_identifier}'.")
      end
    end

    # Error that is raised during site compilation when an item uses a filter
    # that is not known.
    class UnknownFilter < Generic
      def initialize(filter_name)
        super("The requested filter, #{filter_name}, does not exist.")
      end
    end

    # Error that is raised during site compilation when a layout is compiled
    # for which the filter cannot be determined. This is similar to the
    # UnknownFilterError, but specific for filters for layouts.
    class CannotDetermineFilter < Generic
      def initialize(layout_identifier)
        super("The filter to be used for the '#{layout_identifier}' could not be determined. Make sure the layout does have a filter.")
      end
    end

    # Error that is raised when data is requested when the data is not yet
    # available (possibly due to a missing Nanoc::Site#load_data).
    class DataNotYetAvailable < Generic
      def initialize(type, plural)
        super("#{type} #{plural ? 'are' : 'is'} not available yet. You may be missing a Nanoc::Site#load_data call.")
      end
    end

    # Error that is raised during site compilation when an item (directly or
    # indirectly) includes its own item content, leading to endless recursion.
    class RecursiveCompilation < Generic
      def initialize
        super("A recursive call to item content was detected. Items cannot (directly or indirectly) contain their own content.")
      end
    end

    # Error that is raised when no rules file can be found in the current
    # working directory.
    class NoRulesFileFound < Generic
      def initialize
        super("This site does not have a rules file, which is required for nanoc sites.")
      end
    end

    # Error that is raised when no compilation rule that can be applied to the
    # current item can be found.
    class NoMatchingCompilationRuleFound < Generic
      def initialize(rep)
        super("No compilation rules were found for the '#{rep.item.identifier}' item (rep '#{rep.name}').")
      end
    end

    # Error that is raised when no routing rule that can be applied to the
    # current item can be found.
    class NoMatchingRoutingRuleFound < Generic
      def initialize(rep)
        super("No routing rules were found for the '#{rep.item.identifier}' item (rep '#{rep.name}').")
      end
    end

    # Error that is raised when an rep cannot be compiled because it depends on other representations.
    class UnmetDependency < Generic
      attr_reader :rep
      def initialize(rep)
        @rep = rep
        super("The '#{rep.item.identifier}' item (rep '#{rep.name}') cannot currently be compiled yet due to an unmet dependency.")
      end
    end

  end

end
