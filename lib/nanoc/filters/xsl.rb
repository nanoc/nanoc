# encoding: utf-8
require 'nokogiri'

module Nanoc::Filters
  class XSL < Nanoc::Filter

    # Runs the item content through an [XSLT 1.0](http://www.w3.org/TR/xslt) 
    # StyleSheet.
    #
    # If the XSL Template is a {Nanoc::Layout} params can be defined in the
    # layout configuration in the `Rules` file or inside the XSL file as a
    # YAML attributes.
    # 
    # Uses [Nokogiri](http://nokogiri.org/) as a parser.
    #
    # @example Invoking the filter as a filter
    #
    #     filter :xsl, 
    #            :template => 'path/to/template.xsl',
    #            :foo => 'bar'
    #
    # @example Receiving the `:foo` param in the XSL
    #
    #     <xsl:param name="foo"/>
    #
    # @example Invoking the filter as a layout
    #
    #     compile '/xsl/*' do
    #       layout 'xsl/default'
    #     end
    #     layout 'xsl/default', :xsl,
    #                           :foo => 'bar'
    #
    # @param [String] content The content to filter
    #
    # @param [Hash] params The parameters that the XSL stores in the matching 
    #   `xsl:param`. Because XSL params handles only strings it's strongly 
    #   recomended to put just String values.
    #
    # @option params [Symbol] :template The XSL file path. It's required if
    #   the filter is used with the `#filter` method.
    #
    # @return [String] The filtered content
    def run(content, params={})
      raise RuntimeError, "The XSL filter expects a :template param" if assigns[:layout].nil? and params[:template].nil?
      xml_content = assigns[:layout].nil? ? content : assigns[:content]
      xsl_content = assigns[:layout].nil? ? File.read(params[:template]) : content

      options = assigns[:layout].nil? ? {} : assigns[:layout].attributes.dup

      # clean unwanted options
      options.delete(:file)

      options.merge!(params)

      # Rehashing w/o anything which's not a string to prevent XSL receive weird options
      options = options.inject({}) { |add, (key, value)| add.merge!(key.to_s => value.to_s) }

      xml = ::Nokogiri::XML(xml_content)
      xsl = ::Nokogiri::XSLT(xsl_content)

      xsl.transform(xml, ::Nokogiri::XSLT.quote_params(options)).to_s
    end
  end
end