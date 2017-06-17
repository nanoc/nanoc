# frozen_string_literal: true

require 'helper'

require 'tempfile'

class Nanoc::Filters::XSLTest < Nanoc::TestCase
  SAMPLE_XSL = <<~EOS
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

  SAMPLE_XML_IN = <<~EOS
    <?xml version="1.0" encoding="utf-8"?>
    <report>
      <title>My Report</title>
    </report>
EOS

  SAMPLE_XML_OUT = %r{\A<\?xml version="1.0" encoding="utf-8"\?>\s*<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>My Report</h1>\s*</body>\s*</html>\s*\Z}m

  SAMPLE_XSL_WITH_PARAMS = <<~EOS
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

  SAMPLE_XML_IN_WITH_PARAMS = <<~EOS
    <?xml version="1.0" encoding="utf-8"?>
    <report>
      <title>My Report</title>
    </report>
EOS

  SAMPLE_XML_OUT_WITH_PARAMS = %r{\A<\?xml version="1.0" encoding="utf-8"\?>\s*<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>bar</h1>\s*</body>\s*</html>\s*\Z}m

  SAMPLE_XSL_WITH_OMIT_XML_DECL = <<~EOS
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

  SAMPLE_XML_IN_WITH_OMIT_XML_DECL = <<~EOS
    <?xml version="1.0" encoding="utf-8"?>
    <report>
      <title>My Report</title>
    </report>
EOS

  SAMPLE_XML_OUT_WITH_OMIT_XML_DECL = %r{\A<html>\s*<head>\s*<title>My Report</title>\s*</head>\s*<body>\s*<h1>My Report</h1>\s*</body>\s*</html>\s*\Z}m

  def setup
    super

    config = Nanoc::Int::Configuration.new
    items = Nanoc::Int::IdentifiableCollection.new(config)
    layouts = Nanoc::Int::IdentifiableCollection.new(config)

    @dependency_store = Nanoc::Int::DependencyStore.new(items, layouts, config)
    @dependency_tracker = Nanoc::Int::DependencyTracker.new(@dependency_store)

    @base_item = Nanoc::Int::Item.new('base', {}, '/base.md')

    @dependency_tracker.enter(@base_item)
  end

  def new_view_context
    Nanoc::ViewContext.new(
      reps: :__irrelevat_reps,
      items: :__irrelevat_items,
      dependency_tracker: @dependency_tracker,
      compilation_context: :__irrelevat_compiler,
      snapshot_repo: :__irrelevant_snapshot_repo,
    )
  end

  def test_filter_as_layout
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Int::Item.new(SAMPLE_XML_IN, {}, '/content/')
      item = Nanoc::ItemWithRepsView.new(item, new_view_context)
      layout = Nanoc::Int::Layout.new(SAMPLE_XSL, {}, '/layout/')
      layout = Nanoc::LayoutView.new(layout, new_view_context)

      # Create an instance of the filter
      assigns = {
        item: item,
        layout: layout,
        content: item.raw_content,
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.raw_content)
      assert_match SAMPLE_XML_OUT, result

      # Verify dependencies
      dep = @dependency_store.dependencies_causing_outdatedness_of(@base_item)[0]
      refute_nil dep
    end
  end

  def test_filter_with_params
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Int::Item.new(SAMPLE_XML_IN_WITH_PARAMS, {}, '/content/')
      item = Nanoc::ItemWithRepsView.new(item, new_view_context)
      layout = Nanoc::Int::Layout.new(SAMPLE_XSL_WITH_PARAMS, {}, '/layout/')
      layout = Nanoc::LayoutView.new(layout, new_view_context)

      # Create an instance of the filter
      assigns = {
        item: item,
        layout: layout,
        content: item.raw_content,
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.raw_content, foo: 'bar')
      assert_match SAMPLE_XML_OUT_WITH_PARAMS, result

      # Verify dependencies
      dep = @dependency_store.dependencies_causing_outdatedness_of(@base_item)[0]
      refute_nil dep
    end
  end

  def test_filter_with_omit_xml_decl
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Int::Item.new(SAMPLE_XML_IN_WITH_OMIT_XML_DECL, {}, '/content/')
      item = Nanoc::ItemWithRepsView.new(item, new_view_context)
      layout = Nanoc::Int::Layout.new(SAMPLE_XSL_WITH_OMIT_XML_DECL, {}, '/layout/')
      layout = Nanoc::LayoutView.new(layout, new_view_context)

      # Create an instance of the filter
      assigns = {
        item: item,
        layout: layout,
        content: item.raw_content,
      }
      filter = ::Nanoc::Filters::XSL.new(assigns)

      # Run the filter and validate the results
      result = filter.setup_and_run(layout.raw_content)
      assert_match SAMPLE_XML_OUT_WITH_OMIT_XML_DECL, result

      # Verify dependencies
      dep = @dependency_store.dependencies_causing_outdatedness_of(@base_item)[0]
      refute_nil dep
    end
  end
end
