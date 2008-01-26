module Nanoc

  # Nanoc::Plugin is the superclass for all plugins, such as filters,
  # layout processors and data sources.
  class Plugin

    class << self

      attr_accessor :identifiers # :nodoc:

      # Sets or returns the identifiers for this plugin.
      # 
      # When given a list of identifier symbols, sets the identifiers for
      # this plugin. When given nothing, returns an array of identifier
      # symbols for this plugin.
      def identifiers(*idents)
        @identifiers = [] unless instance_variables.include?('@identifiers')
        idents.empty? ? @identifiers : @identifiers = idents
      end

      # Sets or returns the identifier for this plugin.
      # 
      # When given an identifier symbols, sets the identifier for this plugin.
      # When given nothing, returns the identifier for this plugin.
      def identifier(ident=nil)
        @identifiers = [] unless instance_variables.include?('@identifiers')
        ident.nil? ? @identifiers.first : identifiers(ident)
      end

    end

  end

end
