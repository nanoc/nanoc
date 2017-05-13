# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#linkto
  module LinkTo
    require 'nanoc/helpers/html_escape'
    include Nanoc::Helpers::HTMLEscape

    # @param [String] text
    #
    # @param [Hash] attributes
    #
    # @return [String]
    def link_to(text, target, attributes = {})
      # Find path
      path =
        case target
        when String
          target
        when Nanoc::ItemWithRepsView, Nanoc::ItemWithoutRepsView, Nanoc::ItemRepView
          raise "Cannot create a link to #{target.inspect} because this target is not outputted (its routing rule returns nil)" if target.path.nil?
          target.path
        else
          raise ArgumentError, "Cannot link to #{target.inspect} (expected a string or an item, not a #{target.class.name})"
        end

      # Join attributes
      attributes = attributes.reduce('') do |memo, (key, value)|
        memo + key.to_s + '="' + h(value) + '" '
      end

      # Create link
      "<a #{attributes}href=\"#{h path}\">#{text}</a>"
    end

    # @param [String] text
    #
    # @param [Hash] attributes
    #
    # @return [String]
    def link_to_unless_current(text, target, attributes = {})
      # Find path
      path = target.is_a?(String) ? target : target.path

      if @item_rep && @item_rep.path == path
        # Create message
        "<span class=\"active\">#{text}</span>"
      else
        link_to(text, target, attributes)
      end
    end

    # @return [String]
    def relative_path_to(target)
      require 'pathname'

      # Find path
      if target.is_a?(String)
        path = target
      else
        path = target.path
        if path.nil?
          # TODO: get proper error
          raise "Cannot get the relative path to #{target.inspect} because this target is not outputted (its routing rule returns nil)"
        end
      end

      # Handle Windows network (UNC) paths
      if path.start_with?('//', '\\\\')
        return path
      end

      # Get source and destination paths
      dst_path = Pathname.new(path)
      if @item_rep.path.nil?
        # TODO: get proper error
        raise "Cannot get the relative path to #{path} because the current item representation, #{@item_rep.inspect}, is not outputted (its routing rule returns nil)"
      end
      src_path = Pathname.new(@item_rep.path)

      # Calculate the relative path (method depends on whether destination is
      # a directory or not).
      from = src_path.to_s.end_with?('/') ? src_path : src_path.dirname
      relative_path = dst_path.relative_path_from(from).to_s

      # Add trailing slash if necessary
      if dst_path.to_s.end_with?('/')
        relative_path << '/'
      end

      # Done
      relative_path
    end
  end
end
