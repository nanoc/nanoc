module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#capturing
  module Capturing
    # @overload content_for(name, params = {}, &block)
    #   @param [Symbol, String] name
    #   @option params [Symbol] existing
    #   @return [void]
    #
    # @overload content_for(item, name)
    #   @param [Symbol, String] name
    #   @return [String]
    def content_for(*args, &block)
      if block_given? # Set content
        # Get args
        case args.size
        when 1
          name = args[0]
          params = {}
        when 2
          name = args[0]
          params = args[1]
        else
          raise ArgumentError, 'expected 1 or 2 argument (the name ' \
            "of the capture, and optionally params) but got #{args.size} instead"
        end
        name = args[0]
        existing_behavior = params.fetch(:existing, :error)

        # Capture
        content = capture(&block)

        # Prepare for store
        snapshot_contents = @item.reps[:default].unwrap.snapshot_contents
        capture_name = "__capture_#{name}".to_sym
        case existing_behavior
        when :overwrite
          snapshot_contents[capture_name] = ''
        when :append
          snapshot_contents[capture_name] ||= ''
        when :error
          if snapshot_contents[capture_name] && snapshot_contents[capture_name] != content
            # FIXME: get proper exception
            raise "a capture named #{name.inspect} for #{@item.identifier} already exists"
          else
            snapshot_contents[capture_name] = ''
          end
        else
          raise ArgumentError, 'expected :existing_behavior param to #content_for to be one of ' \
            ":overwrite, :append, or :error, but #{existing_behavior.inspect} was given"
        end

        # Store
        snapshot_contents[capture_name] << content
      else # Get content
        if args.size != 2
          raise ArgumentError, 'expected 2 arguments (the item ' \
            "and the name of the capture) but got #{args.size} instead"
        end
        item = args[0]
        name = args[1]

        rep = item.reps[:default].unwrap

        # Create dependency
        if @item.nil? || item != @item.unwrap
          dependency_tracker = @config._context.dependency_tracker
          dependency_tracker.bounce(item.unwrap, raw_content: true, attributes: true, compiled_content: true, path: true)

          unless rep.compiled?
            Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(rep))
            return content_for(*args, &block)
          end
        end

        rep.snapshot_contents["__capture_#{name}".to_sym]
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
      erbout_addition = erbout[erbout_length..-1]

      # Remove addition
      erbout[erbout_length..-1] = ''

      # Depending on how the filter outputs, the result might be a
      # single string or an array of strings (slim outputs the latter).
      erbout_addition = erbout_addition.join if erbout_addition.is_a? Array

      # Done.
      erbout_addition
    end
  end
end
