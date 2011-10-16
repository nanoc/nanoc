# encoding: utf-8
require 'nokogiri'

module Nanoc::Filters

  # @since 3.3.0
  class XSL < Nanoc::Filter

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
    # @param [String] content The XML content to transform
    #
    # @param [Hash] params The parameters that will be stored in corresponding
    #   `xsl:param` elements.
    #
    # @return [String] The transformed content
    def run(content, params={})
      if assigns[:layout].nil?
        raise "The XSL filter can only be run as a layout"
      end

      xml = ::Nokogiri::XML(content)
      xsl = ::Nokogiri::XSLT(assigns[:content])

      xsl.transform(xml, ::Nokogiri::XSLT.quote_params(params)).to_s
    end

  end

end
