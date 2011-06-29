# encoding: utf-8

require 'redcloth'

module Nanoc::Filters
  class RedCloth < Nanoc::Filter

    # Runs the content through [RedCloth](http://redcloth.org/). This method
    # takes the following options:
    #
    # * `:filter_class`
    # * `:filter_html`
    # * `:filter_ids`
    # * `:filter_style`
    # * `:hard_breaks`
    # * `:lite_mode`
    # * `:no_span_caps`
    # * `:sanitize_htm`
    #
    # Each of these options sets the corresponding attribute on the `RedCloth`
    # instance. For example, when the `:hard_breaks => false` option is passed
    # to this filter, the filter will call `r.hard_breaks = false` (with `r`
    # being the `RedCloth` instance).
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Create formatter
      r = ::RedCloth.new(content)

      # Set options
      r.filter_classes = params[:filter_classes] if params.has_key?(:filter_classes)
      r.filter_html    = params[:filter_html]    if params.has_key?(:filter_html)
      r.filter_ids     = params[:filter_ids]     if params.has_key?(:filter_ids)
      r.filter_styles  = params[:filter_styles]  if params.has_key?(:filter_styles)
      r.hard_breaks    = params[:hard_breaks]    if params.has_key?(:hard_breaks)
      r.lite_mode      = params[:lite_mode]      if params.has_key?(:lite_mode)
      r.no_span_caps   = params[:no_span_caps]   if params.has_key?(:no_span_caps)
      r.sanitize_html  = params[:sanitize_html]  if params.has_key?(:sanitize_html)

      # Get result
      r.to_html
    end

  end
end
