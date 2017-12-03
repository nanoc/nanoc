# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#rendering
  module Rendering
    include Nanoc::Helpers::Capturing

    # @param [String] identifier
    # @param [Hash] other_assigns
    #
    # @raise [Nanoc::Int::Errors::UnknownLayout]
    # @raise [Nanoc::Int::Errors::CannotDetermineFilter]
    # @raise [Nanoc::Int::Errors::UnknownFilter]
    #
    # @return [String, nil]
    def render(identifier, other_assigns = {}, &block)
      # Find layout
      layout_view = @layouts[identifier]
      layout_view ||= @layouts[identifier.__nanoc_cleaned_identifier]
      raise Nanoc::Int::Errors::UnknownLayout.new(identifier) if layout_view.nil?
      layout = layout_view.unwrap

      # Visit
      dependency_tracker = @config._context.dependency_tracker
      dependency_tracker.bounce(layout, raw_content: true)

      # Capture content, if any
      captured_content = block_given? ? capture(&block) : nil

      # Get assigns
      assigns = {
        content: captured_content,
        item: @item,
        item_rep: @item_rep,
        items: @items,
        layout: layout_view,
        layouts: @layouts,
        config: @config,
      }.merge(other_assigns)

      # Get filter name
      filter_name, filter_args = *@config._context.compilation_context.filter_name_and_args_for_layout(layout)
      raise Nanoc::Int::Errors::CannotDetermineFilter.new(layout.identifier) if filter_name.nil?

      # Get filter class
      filter_class = Nanoc::Filter.named!(filter_name)

      # Create filter
      filter = filter_class.new(assigns)

      # Layout
      content = layout.content
      arg = content.binary? ? content.filename : content.string
      result = filter.setup_and_run(arg, filter_args)

      # Append to erbout if we have a block
      if block_given?
        # Append result and return nothing
        erbout = eval('_erbout', block.binding)
        erbout << result
        ''
      else
        # Return result
        result
      end
    end
  end
end
