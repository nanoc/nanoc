# encoding: utf-8

module Nanoc3

  # Nanoc3::Filter is responsible for filtering items. It is the superclass
  # for all textual filters.
  #
  # A filter instance should only be used once. Filters should not be reused
  # since they store state.
  #
  # When creating a filter with a hash containing assigned variables, those
  # variables will be made available in the `@assigns` instance variable and
  # the {#assigns} method. The assigns itself will also be available as
  # instance variables and instance methods.
  #
  # @example Accessing assigns in different ways
  #
  #   filter = SomeFilter.new({ :foo => 'bar' })
  #   filter.instance_eval { @assigns[:foo] }
  #     # => 'bar'
  #   filter.instance_eval { assigns[:foo] }
  #     # => 'bar'
  #   filter.instance_eval { @foo }
  #     # => 'bar'
  #   filter.instance_eval { foo }
  #     # => 'bar'
  #
  # @abstract Subclass and override {#run} to implement a custom filter.
  class Filter < Context

    # A hash containing variables that will be made available during
    # filtering.
    #
    # @return [Hash]
    attr_reader :assigns

    extend Nanoc3::PluginRegistry::PluginMethods

    class << self

      # Sets the new type for the filter (`:binary` or `:text`).
      #
      # @param [Symbol] arg The new type of this filter
      #
      # @return [void]
      def type(arg)
        @type = arg
      end

      # @return [Boolean] True if this is a binary filter, false otherwise
      def binary?
        (@type || :text) == :binary
      end

    end

    # Creates a new filter that has access to the given assigns.
    #
    # @param [Hash] hash A hash containing variables that should be made
    # available during filtering.
    def initialize(hash={})
      @assigns = hash
      super
    end

    # Runs the filter on the given content or filename.
    #
    # @abstract
    #
    # @param [String] content_or_filename The unprocessed content that should
    # be filtered (if the item is a textual item) or the path to the file that
    # should be fitlered (if the item is a binar item)
    #
    # @param [Hash] params A hash containing parameters. Filter subclasses can
    # use these parameters to allow modifying the filter's behaviour.
    #
    # @return [String] The filtered content (if the item is a textual item) or
    # a path to a newly generated file containing the filtered content (if the
    # item is a binary item)
    def run(content_or_filename, params={})
      raise NotImplementedError.new("Nanoc3::Filter subclasses must implement #run")
    end

    # Returns a filename that is used to write data to. This method is only
    # used on binary items. When running a binary filter on a file, the
    # resulting file must end up in the location returned by this method.
    #
    # @return [String] The output filename
    def output_filename
      @output_filename ||= begin
        require 'tempfile'

        tempfile = Tempfile.new(filename.gsub(/[^a-z]/, '-'), 'tmp')
        new_filename = tempfile.path
        tempfile.close!

        new_filename
      end
    end

    # Returns the filename associated with the item that is being filtered.
    # It is in the format `item <identifier> (rep <name>)`.
    #
    # @return [String] The filename
    def filename
      if assigns[:layout]
        "layout #{assigns[:layout].identifier}"
      elsif assigns[:item]
        "item #{assigns[:item].identifier} (rep #{assigns[:item_rep].name})"
      else
        '?'
      end
    end

  end

end
