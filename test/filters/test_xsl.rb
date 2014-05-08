# encoding: utf-8

require 'tempfile'

class Nanoc::Filters::XSLTest < Nanoc::TestCase

  def sample_xsl
    <<-EOS
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
  end

  def sample_xml_in
    Nanoc::TextualContent.new(<<-EOS, File.absolute_path('content/foo.xml'))
<?xml version="1.0" encoding="utf-8"?>
<report>
  <title>My Report</title>
</report>
EOS
  end

  def sample_xml_out
    %r{\A<\?xml version="1.0" encoding="utf-8"\?>\s*<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>My Report</h1>\s*</body>\s*</html>\s*\Z}m
  end

  def sample_xsl_with_params
    <<-EOS
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
  end

  def sample_xml_in_with_params
    Nanoc::TextualContent.new(<<-EOS, File.absolute_path('content/foo.xml'))
<?xml version="1.0" encoding="utf-8"?>
<report>
  <title>My Report</title>
</report>
EOS
  end

  def sample_xml_out_with_params
    %r{\A<\?xml version="1.0" encoding="utf-8"\?>\s*<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>bar</h1>\s*</body>\s*</html>\s*\Z}m
  end

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
      item = Nanoc::Item.new(sample_xml_in, {}, '/content.xml')
      layout = Nanoc::Layout.new(sample_xsl, {}, '/layout.xsl')

      # Create an instance of the filter
      assigns = {
        :item => item,
        :layout => layout,
        :content => item.content,
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.content)
      assert_match sample_xml_out, result
    end
  end

  def test_filter_with_params
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Item.new(sample_xml_in_with_params, {}, '/content.xml')
      layout = Nanoc::Layout.new(sample_xsl_with_params, {}, '/layout.xsl')

      # Create an instance of the filter
      assigns = {
        :item => item,
        :layout => layout,
        :content => item.content,
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.content, :foo => 'bar')
      assert_match sample_xml_out_with_params, result
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
        :content => item.content
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.content)
      assert_match SAMPLE_XML_OUT_WITH_OMIT_XML_DECL, result
    end
  end

end
