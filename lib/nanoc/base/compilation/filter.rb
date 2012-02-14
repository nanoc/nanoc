# encoding: utf-8

module Nanoc

  # Nanoc::Filter is responsible for filtering items. It is the superclass
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

    # The path to the directory where temporary binary items are stored
    TMP_BINARY_ITEMS_DIR = 'tmp/binary_items'

    # A hash containing variables that will be made available during
    # filtering.
    #
    # @return [Hash]
    attr_reader :assigns

    extend Nanoc::PluginRegistry::PluginMethods

    class << self

      # Sets the new type for the filter. The type can be `:binary` (default)
      # or `:text`. The given argument can either be a symbol indicating both
      # “from” and “to” types, or a hash where the only key is the “from” type
      # and the only value is the “to” type.
      #
      # @example Specifying a text-to-text filter
      #
      #     type :text
      #
      # @example Specifying a text-to-binary filter
      #
      #     type :text => :binary
      #
      # @param [Symbol, Hash] arg The new type of this filter
      #
      # @return [void]
      def type(arg)
        if arg.is_a?(Hash)
          @from, @to = arg.keys[0], arg.values[0]
        else
          @from, @to = arg, arg
        end
      end

      # @return [Boolean] True if this filter can be applied to binary item
      #   representations, false otherwise
      def from_binary?
        (@from || :text) == :binary
      end

      # @return [Boolean] True if this filter results in a binary item
      #   representation, false otherwise
      def to_binary?
        (@to || :text) == :binary
      end

    end

    # Creates a new filter that has access to the given assigns.
    #
    # @param [Hash] hash A hash containing variables that should be made
    #   available during filtering.
    def initialize(hash={})
      @assigns = hash
      super
    end

    # Runs the filter on the given content or filename.
    #
    # @abstract
    #
    # @param [String] content_or_filename The unprocessed content that should
    #   be filtered (if the item is a textual item) or the path to the file
    #   that should be filtered (if the item is a binary item)
    #
    # @param [Hash] params A hash containing parameters. Filter subclasses can
    #   use these parameters to allow modifying the filter's behaviour.
    #
    # @return [String, void] If the filter output binary content, the return
    #   value is undefined; if the filter outputs textual content, the return
    #   value will be the filtered content.
    def run(content_or_filename, params={})
      raise NotImplementedError.new("Nanoc::Filter subclasses must implement #run")
    end

    # Returns a filename that is used to write data to. This method is only
    #   used on binary items. When running a binary filter on a file, the
    #   resulting file must end up in the location returned by this method.
    #
    # The returned filename will be absolute, so it is safe to change to
    #   another directory inside the filter.
    #
    # @return [String] The output filename
    def output_filename
      @output_filename ||= begin
        FileUtils.mkdir_p(TMP_BINARY_ITEMS_DIR)
        tempfile = Tempfile.new('', TMP_BINARY_ITEMS_DIR)
        new_filename = tempfile.path
        tempfile.close!

        File.expand_path(new_filename)
      end
    end

    # Returns the filename associated with the item that is being filtered.
    #   It is in the format `item <identifier> (rep <name>)`.
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

    # Creates a dependency from the item that is currently being filtered onto
    # the given collection of items. In other words, require the given items
    # to be compiled first before this items is processed.
    #
    # @param [Array<Nanoc::Item>] items The items that are depended on.
    #
    # @return [void]
    def depend_on(items)
      # Notify
      items.each do |item|
        Nanoc::NotificationCenter.post(:visit_started, item)
        Nanoc::NotificationCenter.post(:visit_ended,   item)
      end

      # Raise unmet dependency error if necessary
      items.each do |item|
        rep = item.reps.find { |r| !r.compiled? }
        raise Nanoc::Errors::UnmetDependency.new(rep) if rep
      end
    end

  end

end
