class Nanoc::Filters::LessTest < Nanoc::TestCase
  def view_context
    dependency_tracker = Nanoc::Int::DependencyTracker.new(nil)
    Nanoc::ViewContext.new(reps: nil, items: nil, dependency_tracker: dependency_tracker, compiler: nil)
  end

  def test_filter
    if_have 'less' do
      # Create item
      @item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('blah', { content_filename: 'content/foo/bar.txt' }, '/foo/bar/'), view_context)

      # Create filter
      filter = ::Nanoc::Filters::Less.new(item: @item, items: [@item])

      # Run filter
      result = filter.setup_and_run('.foo { bar: 1 + 1 }')
      assert_match(/\.foo\s*\{\s*bar:\s*2;?\s*\}/, result)
    end
  end

  def test_filter_with_paths_relative_to_site_directory
    if_have 'less' do
      # Create file to import
      FileUtils.mkdir_p('content/foo/bar')
      File.open('content/foo/bar/imported_file.less', 'w') { |io| io.write('p { color: red; }') }

      # Create item
      @item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('blah', { content_filename: 'content/foo/bar.txt' }, '/foo/bar/'), view_context)

      # Create filter
      filter = ::Nanoc::Filters::Less.new(item: @item, items: [@item])

      # Run filter
      result = filter.setup_and_run('@import "content/foo/bar/imported_file.less";')
      assert_match(/p\s*\{\s*color:\s*red;?\s*\}/, result)
    end
  end

  def test_filter_with_paths_relative_to_current_file
    if_have 'less' do
      # Create file to import
      FileUtils.mkdir_p('content/foo/bar')
      File.open('content/foo/bar/imported_file.less', 'w') { |io| io.write('p { color: red; }') }

      # Create item
      File.open('content/foo/bar.txt', 'w') { |io| io.write('meh') }
      @item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('blah', { content_filename: 'content/foo/bar.txt' }, '/foo/bar/'), view_context)

      # Create filter
      filter = ::Nanoc::Filters::Less.new(item: @item, items: [@item])

      # Run filter
      result = filter.setup_and_run('@import "bar/imported_file.less";')
      assert_match(/p\s*\{\s*color:\s*red;?\s*\}/, result)
    end
  end

  def test_compression
    if_have 'less' do
      # Create item
      @item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('blah', { content_filename: 'content/foo/bar.txt' }, '/foo/bar/'), view_context)

      # Create filter
      filter = ::Nanoc::Filters::Less.new(item: @item, items: [@item])

      # Run filter with compress option
      result = filter.setup_and_run('.foo { bar: a; } .bar { foo: b; }', compress: true)
      assert_match(/^\.foo\{bar:a\}\n?\.bar\{foo:b\}/, result)
    end
  end
end
