# frozen_string_literal: true

module Nanoc
  module Core
    # Nanoc::Core::Filter is responsible for filtering items. It is the superclass
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
    class Filter < Nanoc::Core::Context
      extend DDPlugin::Plugin

      include Nanoc::Core::ContractsSupport

      # @api private
      TMP_BINARY_ITEMS_DIR = 'binary_items'

      class UnknownFilterError < Nanoc::Core::Error
        include Nanoc::Core::ContractsSupport

        contract C::Or[String, Symbol] => self
        def initialize(filter_name)
          super("The requested filter, “#{filter_name}”, does not exist.")
        end
      end

      class OutputNotWrittenError < Nanoc::Core::Error
        include Nanoc::Core::ContractsSupport

        contract C::Or[String, Symbol], String => self
        def initialize(filter_name, output_filename)
          super("The #{filter_name.inspect} filter did not write anything to the required output file, #{output_filename}.")
        end
      end

      class FilterReturnedNilError < Nanoc::Core::Error
        include Nanoc::Core::ContractsSupport

        contract C::Or[String, Symbol] => self
        def initialize(filter_name)
          super("The #{filter_name.inspect} filter returned nil, but is required to return a String.")
        end
      end

      class << self
        def define(ident, &block)
          filter_class = Class.new(::Nanoc::Core::Filter) { identifier(ident) }
          filter_class.send(:define_method, :run) do |content, params = {}|
            instance_exec(content, params, &block)
          end
        end

        def named!(name)
          klass = named(name)
          raise UnknownFilterError.new(name) if klass.nil?

          klass
        end

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
            @from = arg.keys[0]
            @to = arg.values[0]
          else
            @from = arg
            @to = arg
          end
        end

        # @return [Boolean] True if this filter can be applied to binary item
        #   representations, false otherwise
        #
        # @api private
        def from_binary?
          (@from || :text) == :binary
        end

        # @return [Boolean] True if this filter results in a binary item
        #   representation, false otherwise
        #
        # @api private
        def to_binary?
          (@to || :text) == :binary
        end

        # @api private
        def to_text?
          (@to || :text) == :text
        end

        # @return [Boolean]
        #
        # @api private
        def always_outdated?
          @always_outdated || false
        end

        # Marks this filter as always causing the item rep to be outdated. This is useful for filters
        # that cannot do dependency tracking properly.
        #
        # @return [void]
        def always_outdated
          @always_outdated = true
        end

        # @overload requires(*requires)
        #   Sets the required libraries for this filter.
        #   @param [Array<String>] requires A list of library names that are required
        #   @return [void]
        # @overload requires
        #   Returns the required libraries for this filter.
        #   @return [Enumerable<String>] This filter’s list of library names that are required
        def requires(*requires)
          if requires.any?
            @requires = requires
          else
            @requires || []
          end
        end

        # Requires the filter’s required library if necessary.
        #
        # @return [void]
        #
        # @api private
        def setup
          @_setup ||= begin
            requires.each { |r| require r }
            true
          end
        end
      end

      # Creates a new filter that has access to the given assigns.
      #
      # @param [Hash] hash A hash containing variables that should be made
      #   available during filtering.
      #
      # @api private
      def initialize(hash = {})
        @assigns = hash
        super
      end

      # Sets up the filter and runs the filter. This method passes its arguments
      # to {#run} unchanged and returns the return value from {#run}.
      #
      # @see #run
      #
      # @api private
      def setup_and_run(*args)
        self.class.setup
        run(*args).tap { |res| verify(res) }
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
      def run(content_or_filename, params = {}) # rubocop:disable Lint/UnusedMethodArgument
        raise NotImplementedError.new('Nanoc::Core::Filter subclasses must implement #run')
      end

      def verify(res)
        if self.class.to_binary?
          unless File.file?(output_filename)
            raise Nanoc::Core::Filter::OutputNotWrittenError.new(self.class.identifier, output_filename)
          end
        elsif self.class.to_text?
          unless res
            raise Nanoc::Core::Filter::FilterReturnedNilError.new(self.class.identifier)
          end
        end
      end

      contract C::None => String
      # Returns a filename that is used to write data to. This method is only
      #   used on binary items. When running a binary filter on a file, the
      #   resulting file must end up in the location returned by this method.
      #
      # The returned filename will be absolute, so it is safe to change to
      #   another directory inside the filter.
      #
      # @return [String] The output filename
      def output_filename
        @_output_filename ||=
          Nanoc::Core::TempFilenameFactory.instance.create(TMP_BINARY_ITEMS_DIR)
      end

      contract C::None => String
      # Returns the filename associated with the item that is being filtered.
      #   It is in the format `item <identifier> (rep <name>)`.
      #
      # @return [String] The filename
      #
      # @api private
      def filename
        if @layout
          "layout #{@layout.identifier}"
        elsif @item
          "item #{@item.identifier} (rep #{@item_rep.name})"
        else
          '?'
        end
      end

      # @api private
      def on_main_fiber(&block)
        Fiber.yield(block)
      end

      contract C::ArrayOf[C::Named['Nanoc::Core::BasicItemView']] => C::Any
      # Creates a dependency from the item that is currently being filtered onto
      # the given collection of items. In other words, require the given items
      # to be compiled first before this items is processed.
      #
      # @return [void]
      def depend_on(items)
        items.flat_map(&:reps).flat_map(&:raw_path)
        items.each(&:raw_filename)
      end
    end
  end
end
