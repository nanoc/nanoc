# encoding: utf-8

require 'tempfile'

class Nanoc::Filters::XSLTest < Nanoc::TestCase

  SAMPLE_XSL = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>
  <xsl:template match="/">
    <html>
      <head>
        <title><xsl:value-of select="report/title"/></title>
      </head>
      <body>
        <h1><xsl:value-of select="report/title"/></h1>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
EOS

  SAMPLE_XML_IN = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<report>
  <title>My Report</title>
</report>
EOS

  SAMPLE_XML_OUT = %r{\A<\?xml version="1.0" encoding="utf-8"\?>\s*<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>My Report</h1>\s*</body>\s*</html>\s*\Z}m

  SAMPLE_XSL_WITH_PARAMS = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>
  <xsl:param name="foo"/>
  <xsl:template match="/">
    <html>
      <head>
        <title><xsl:value-of select="report/title"/></title>
      </head>
      <body>
        <h1><xsl:value-of select="$foo"/></h1>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
EOS

  SAMPLE_XML_IN_WITH_PARAMS = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<report>
  <title>My Report</title>
</report>
EOS

  SAMPLE_XML_OUT_WITH_PARAMS = %r{\A<\?xml version="1.0" encoding="utf-8"\?>\s*<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>bar</h1>\s*</body>\s*</html>\s*\Z}m

  SAMPLE_XSL_WITH_OMIT_XML_DECL = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"
              omit-xml-declaration="yes"/>
  <xsl:template match="/">
    <html>
      <head>
        <title><xsl:value-of select="report/title"/></title>
      </head>
      <body>
        <h1><xsl:value-of select="report/title"/></h1>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
EOS

  SAMPLE_XML_IN_WITH_OMIT_XML_DECL = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<report>
  <title>My Report</title>
</report>
EOS

  SAMPLE_XML_OUT_WITH_OMIT_XML_DECL = %r{\A<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>My Report</h1>\s*</body>\s*</html>\s*\Z}m

  def test_filter_as_layout
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Item.new(SAMPLE_XML_IN,
                             { },
                             '/content/')
      layout = Nanoc::Layout.new(SAMPLE_XSL,
                                 { },
                                 '/layout/')

      # Create an instance of the filter
      assigns = {
        :item => item,
        :layout => layout,
        :content => item.raw_content
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.raw_content)
      assert_match SAMPLE_XML_OUT, result
    end
  end

  def test_filter_with_params
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Item.new(SAMPLE_XML_IN_WITH_PARAMS,
                             { },
                             '/content/')
      layout = Nanoc::Layout.new(SAMPLE_XSL_WITH_PARAMS,
                                 { },
                                 '/layout/')

      # Create an instance of the filter
      assigns = {
        :item => item,
        :layout => layout,
        :content => item.raw_content
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.raw_content,
                                    :foo => 'bar')
      assert_match SAMPLE_XML_OUT_WITH_PARAMS, result
    end
  end

  def test_filter_with_omit_xml_decl
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Item.new(SAMPLE_XML_IN_WITH_OMIT_XML_DECL,
                             { },
                             '/content/')
      layout = Nanoc::Layout.new(SAMPLE_XSL_WITH_OMIT_XML_DECL,
                                 { },
                                 '/layout/')

      # Create an instance of the filter
      assigns = {
        :item => item,
        :layout => layout,
        :content => item.raw_content
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.raw_content)
      assert_match SAMPLE_XML_OUT_WITH_OMIT_XML_DECL, result
    end
  end

end
