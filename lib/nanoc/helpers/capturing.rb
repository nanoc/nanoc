# encoding: utf-8

module Nanoc::Helpers

  # Provides functionality for “capturing” content in one place and reusing
  # this content elsewhere.
  #
  # For example, suppose you want the sidebar of your site to contain a short
  # summary of the item. You could put the summary in the meta file, but
  # that’s not possible when the summary contains eRuby. You could also put
  # the sidebar inside the actual item, but that’s not very pretty. Instead,
  # you write the summary on the item itself, but capture it, and print it in
  # the sidebar layout.
  #
  # This helper has been tested with ERB and Haml. Other filters may not work
  # correctly.
  #
  # @example Capturing content for a summary
  #
  #   <% content_for :summary do %>
  #     <p>On this item, nanoc is introduced, blah blah.</p>
  #   <% end %>
  #
  # @example Showing captured content in a sidebar
  #
  #   <div id="sidebar">
  #     <h3>Summary</h3>
  #     <%= content_for(@item, :summary) || '(no summary)' %>
  #   </div>
  #
  # @example Showing captured content in a sidebar the old, deprecated way (do not use or I will become very angry)
  #
  #   <div id="sidebar">
  #     <h3>Summary</h3>
  #     <%= @item[:content_for_summary] || '(no summary)' %>
  #   </div>
  module Capturing

    # @api private
    class CapturesStore

      def initialize
        @store = {}
      end

      def []=(item, name, content)
        @store[item.identifier] ||= {}
        @store[item.identifier][name] = content
      end

      def [](item, name)
        @store[item.identifier] ||= {}
        @store[item.identifier][name]
      end

    end

    class ::Nanoc::Site

      # @api private
      def captures_store
        @captures_store ||= CapturesStore.new
      end

      # @api private
      def captures_store_compiled_items
        require 'set'
        @captures_store_compiled_items ||= Set.new
      end

    end

    # @overload content_for(name, &block)
    #
    #   Captures the content inside the block and stores it so that it can be
    #   referenced later on. The same method, {#content_for}, is used for
    #   getting the captured content as well as setting it. When capturing,
    #   the content of the block itself will not be outputted.
    #
    #   For backwards compatibility, it is also possible to fetch the captured
    #   content by getting the contents of the attribute named `content_for_`
    #   followed by the given name. This way of accessing captures is
    #   deprecated.
    #
    #   @param [Symbol, String] name The base name of the attribute into which
    #     the content should be stored
    #
    #   @return [void]
    #
    # @overload content_for(item, name)
    #
    #   Fetches the capture with the given name from the given item and
    #   returns it.
    #
    #   @param [Nanoc::Item] item The item for which to get the capture
    #
    #   @param [Symbol, String] name The name of the capture to fetch
    #
    #   @return [String] The stored captured content
    def content_for(*args, &block)
      if block_given? # Set content
        # Get args
        if args.size != 1
          raise ArgumentError, "expected 1 argument (the name " + 
            "of the capture) but got #{args.size} instead"
        end
        name = args[0]

        # Capture and store
        content = capture(&block)
        @site.captures_store[@item, name.to_sym] = content
      else # Get content
        # Get args
        if args.size != 2
          raise ArgumentError, "expected 2 arguments (the item " +
            "and the name of the capture) but got #{args.size} instead"
        end
        item = args[0]
        name = args[1]

        # Create dependency
        current_item = @site.compiler.dependency_tracker.top
        if item != current_item
          Nanoc::NotificationCenter.post(:visit_started, item)
          Nanoc::NotificationCenter.post(:visit_ended,   item)

          # This is an extremely ugly hack to get the compiler to recompile the
          # item from which we use content. For this, we need to manually edit
          # the content attribute to reset it. :(
          # FIXME clean this up
          if !@site.captures_store_compiled_items.include? item
            @site.captures_store_compiled_items << item 
            item.forced_outdated = true
            item.reps.each do |r|
              raw_content = item.raw_content
              r.content = { :raw => raw_content, :last => raw_content }
              @site.compiler.send(:compile_rep, r)
            end
          end
        end

        # Get content
        @site.captures_store[item, name.to_sym]
      end
    end

    # Evaluates the given block and returns its contents. The contents of the
    # block is not outputted.
    #
    # @return [String] The captured result
    def capture(&block)
      # Get erbout so far
      erbout = eval('_erbout', block.binding)
      erbout_length = erbout.length

      # Execute block
      block.call

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
