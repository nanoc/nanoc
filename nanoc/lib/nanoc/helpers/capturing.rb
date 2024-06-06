# frozen_string_literal: true

module Nanoc::Helpers
  # @see https://nanoc.app/doc/reference/helpers/#capturing
  module Capturing
    # @api private
    class SetContent
      include Nanoc::Helpers::Capturing

      def initialize(name, params, item)
        @name = name
        @params = params
        @item = item
      end

      def run(&)
        existing_behavior = @params.fetch(:existing, :error)

        # Capture
        content_string = capture(&)

        # Get existing contents and prep for store
        compiled_content_store = @item._context.compiled_content_store
        rep = @item.reps[:default]._unwrap
        capture_name = :"__capture_#{@name}"
        old_content_string =
          case existing_behavior
          when :overwrite
            ''
          when :append
            c = compiled_content_store.get(rep, capture_name)
            c ? c.string : ''
          when :error
            contents = compiled_content_store.get(rep, capture_name)
            if contents && contents.string != content_string
              # FIXME: get proper exception
              raise "a capture named #{@name.inspect} for #{@item.identifier} already exists"
            else
              ''
            end
          else
            raise ArgumentError, 'expected :existing_behavior param to #content_for to be one of ' \
              ":overwrite, :append, or :error, but #{existing_behavior.inspect} was given"
          end

        # Store
        new_content = Nanoc::Core::TextualContent.new(old_content_string + content_string)
        compiled_content_store.set(rep, capture_name, new_content)
      end
    end

    # @api private
    class GetContent
      def initialize(requested_item, name, item, config)
        @requested_item = requested_item
        @name = name
        @item = item
        @config = config
      end

      def run
        rep = @requested_item.reps[:default]._unwrap

        # Create dependency
        if @item.nil? || @requested_item != @item._unwrap
          dependency_tracker = @config._context.dependency_tracker
          dependency_tracker.bounce(@requested_item._unwrap, compiled_content: true)

          unless rep.compiled?
            # FIXME: is :last appropriate?
            Fiber.yield(Nanoc::Core::Errors::UnmetDependency.new(rep, :last))
            return run
          end
        end

        compiled_content_store = @config._context.compiled_content_store
        content = compiled_content_store.get(rep, :"__capture_#{@name}")
        content&.string
      end
    end

    # @overload content_for(name, &block)
    #   @param [Symbol, String] name
    #   @return [void]
    #
    # @overload content_for(name, params, &block)
    #   @param [Symbol, String] name
    #   @option params [Symbol] existing
    #   @return [void]
    #
    # @overload content_for(name, content)
    #   @param [Symbol, String] name
    #   @param [String] content
    #   @return [void]
    #
    # @overload content_for(name, params, content)
    #   @param [Symbol, String] name
    #   @param [String] content
    #   @option params [Symbol] existing
    #   @return [void]
    #
    # @overload content_for(item, name)
    #   @param [Symbol, String] name
    #   @return [String]
    def content_for(*args, &)
      if block_given? # Set content
        name = args[0]
        params =
          case args.size
          when 1
            {}
          when 2
            args[1]
          else
            raise ArgumentError, 'expected 1 or 2 argument (the name ' \
              "of the capture, and optionally params) but got #{args.size} instead"
          end

        SetContent.new(name, params, @item).run(&)
      elsif args.size > 1 && (args.first.is_a?(Symbol) || args.first.is_a?(String)) # Set content
        name = args[0]
        content = args.last
        params =
          case args.size
          when 2
            {}
          when 3
            args[1]
          else
            raise ArgumentError, 'expected 2 or 3 arguments (the name ' \
              "of the capture, optionally params, and the content) but got #{args.size} instead"
          end

        _erbout = +'' # rubocop:disable Lint/UnderscorePrefixedVariableName
        SetContent.new(name, params, @item).run { _erbout << content }
      else # Get content
        if args.size != 2
          raise ArgumentError, 'expected 2 arguments (the item ' \
            "and the name of the capture) but got #{args.size} instead"
        end
        requested_item = args[0]
        name = args[1]

        GetContent.new(requested_item, name, @item, @config).run
      end
    end

    # @return [String]
    def capture(&block)
      # Get erbout so far
      erbout = eval('_erbout', block.binding)
      erbout_length = erbout.length

      # Execute block
      yield

      # Get new piece of erbout
      erbout_addition = erbout[erbout_length..]

      # Remove addition
      erbout[erbout_length..-1] = +''

      # Depending on how the filter outputs, the result might be a
      # single string or an array of strings (slim outputs the latter).
      erbout_addition = erbout_addition.join('') if erbout_addition.is_a? Array

      # Done.
      erbout_addition
    end
  end
end
