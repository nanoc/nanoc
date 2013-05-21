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
    <<-EOS
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
  end

  def sample_xsl_with_params
    <<-EOS
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
    <<-EOS
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
  end

  def test_filter_as_layout
    if_have 'nokogiri' do
      layout = Nanoc::Layout.new(self.sample_xsl, {}, '/layout/')

      filter = ::Nanoc::Filters::XSL.new(:layout => layout)
      result = filter.setup_and_run(self.sample_xml_in)

      assert_equal self.sample_xml_out, result
    end
  end

  def test_filter_with_params
    if_have 'nokogiri' do
      layout = Nanoc::Layout.new(self.sample_xsl_with_params, {}, '/layout/')

      filter = ::Nanoc::Filters::XSL.new(:layout => layout)
      result = filter.setup_and_run(self.sample_xml_in_with_params, :foo => 'bar')

      assert_equal self.sample_xml_out_with_params, result
    end
  end

end
