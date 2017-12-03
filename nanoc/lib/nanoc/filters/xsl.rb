# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class XSL < Nanoc::Filter
    identifier :xsl

    requires 'nokogiri'

    always_outdated

    # Runs the item content through an [XSLT](http://www.w3.org/TR/xslt)
    # stylesheet using  [Nokogiri](http://nokogiri.org/).
    #
    # This filter can only be run for layouts, because it will need both the
    # XML to convert (= the item content) as well as the XSLT stylesheet (=
    # the layout content).
    #
    # Additional parameters can be passed to the layout call. These parameters
    # will be turned into `xsl:param` elements.
    #
    # @example Invoking the filter as a layout
    #
    #     compile '/reports/*/' do
    #       layout 'xsl-report'
    #     end
    #
    #     layout 'xsl-report', :xsl, :awesome => 'definitely'
    #
    # @param [String] _content Ignored. As the filter can be run only as a
    #   layout, the value of the `:content` parameter passed to the class at
    #   initialization is used as the content to transform.
    #
    # @param [Hash] params The parameters that will be stored in corresponding
    #   `xsl:param` elements.
    #
    # @return [String] The transformed content
    def run(_content, params = {})
      Nanoc::Extra::JRubyNokogiriWarner.check_and_warn

      if assigns[:layout].nil?
        raise 'The XSL filter can only be run as a layout'
      end

      xml = ::Nokogiri::XML(assigns[:content])
      xsl = ::Nokogiri::XSLT(assigns[:layout].raw_content)

      xsl.apply_to(xml, ::Nokogiri::XSLT.quote_params(params))
    end
  end
end
