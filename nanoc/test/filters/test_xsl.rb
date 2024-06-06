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

    config = Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults
    items = Nanoc::Core::ItemCollection.new(config)
    layouts = Nanoc::Core::LayoutCollection.new(config)

    @dependency_store = Nanoc::Core::DependencyStore.new(items, layouts, config)
    @dependency_tracker = Nanoc::Core::DependencyTracker.new(@dependency_store)

    @base_item = Nanoc::Core::Item.new('base', {}, '/base.md')

    @dependency_tracker.enter(@base_item)
  end

  def new_view_context
    config = Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults

    items = Nanoc::Core::ItemCollection.new(config)
    layouts = Nanoc::Core::LayoutCollection.new(config)
    reps = Nanoc::Core::ItemRepRepo.new

    site =
      Nanoc::Core::Site.new(
        config:,
        code_snippets: [],
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )

    compiled_content_cache = Nanoc::Core::CompiledContentCache.new(config:)
    compiled_content_store = Nanoc::Core::CompiledContentStore.new

    action_provider =
      Class.new(Nanoc::Core::ActionProvider) do
        def self.for(_context)
          raise NotImplementedError
        end

        def initialize; end
      end.new

    compilation_context =
      Nanoc::Core::CompilationContext.new(
        action_provider:,
        reps:,
        site:,
        compiled_content_cache:,
        compiled_content_store:,
      )

    Nanoc::Core::ViewContextForCompilation.new(
      reps: Nanoc::Core::ItemRepRepo.new,
      items: Nanoc::Core::ItemCollection.new(config),
      dependency_tracker: @dependency_tracker,
      compilation_context:,
      compiled_content_store: Nanoc::Core::CompiledContentStore.new,
    )
  end

  def test_filter_as_layout
    if_have 'nokogiri' do
      # Create our data objects
      item = Nanoc::Core::Item.new(SAMPLE_XML_IN, {}, '/content')
      item = Nanoc::Core::CompilationItemView.new(item, new_view_context)
      layout = Nanoc::Core::Layout.new(SAMPLE_XSL, {}, '/layout')
      layout = Nanoc::Core::LayoutView.new(layout, new_view_context)

      # Create an instance of the filter
      assigns = {
        item:,
        layout:,
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
      item = Nanoc::Core::Item.new(SAMPLE_XML_IN_WITH_PARAMS, {}, '/content')
      item = Nanoc::Core::CompilationItemView.new(item, new_view_context)
      layout = Nanoc::Core::Layout.new(SAMPLE_XSL_WITH_PARAMS, {}, '/layout')
      layout = Nanoc::Core::LayoutView.new(layout, new_view_context)

      # Create an instance of the filter
      assigns = {
        item:,
        layout:,
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
      item = Nanoc::Core::Item.new(SAMPLE_XML_IN_WITH_OMIT_XML_DECL, {}, '/content')
      item = Nanoc::Core::CompilationItemView.new(item, new_view_context)
      layout = Nanoc::Core::Layout.new(SAMPLE_XSL_WITH_OMIT_XML_DECL, {}, '/layout')
      layout = Nanoc::Core::LayoutView.new(layout, new_view_context)

      # Create an instance of the filter
      assigns = {
        item:,
        layout:,
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
