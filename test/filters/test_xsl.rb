# encoding: utf-8

require 'tempfile'

class Nanoc::Filters::XSLTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

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

  SAMPLE_XML_OUT = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<html>
  <head>
    <title>My Report</title>
  </head>
  <body>
    <h1>My Report</h1>
  </body>
</html>
EOS

  SAMPLE_XSL_WITH_PARAMS = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>
  <xsl:template match="/">
    <html>
      <head>
        <title><xsl:value-of select="$foo"/></title>
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

  SAMPLE_XML_OUT_WITH_PARAMS = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<html>
  <head>
    <title>bar</title>
  </head>
  <body>
    <h1>bar</h1>
  </body>
</html>
EOS

  def test_filter_as_layout
    if_have 'nokogiri' do
      layout = Nanoc::Layout.new(SAMPLE_XSL, {}, '/layout/')

      filter = ::Nanoc::Filters::XSL.new(
        :layout => layout, :content => SAMPLE_XSL)
      result = filter.run(SAMPLE_XML_IN)

      assert_equal SAMPLE_XML_OUT, result
    end
  end

  def test_filter_with_params
    if_have 'nokogiri' do
      layout = Nanoc::Layout.new(SAMPLE_XSL_WITH_PARAMS, {}, '/layout/')

      filter = ::Nanoc::Filters::XSL.new(
        :layout => layout, :content => SAMPLE_XSL_WITH_PARAMS)
      result = filter.run(SAMPLE_XML_IN_WITH_PARAMS, :foo => 'bar')

      assert_equal SAMPLE_XML_OUT_WITH_PARAMS, result
    end
  end

end
