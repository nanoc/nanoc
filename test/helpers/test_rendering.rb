class Nanoc::Helpers::RenderingTest < Nanoc::TestCase
  include Nanoc::Helpers::Rendering

  def test_render
    with_site do |site|
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :erb\n")
      end

      File.open('layouts/foo.erb', 'w') do |io|
        io.write 'This is the <%= @layout.identifier %> layout.'
      end

      @site = Nanoc::SiteView.new(site)
      @layouts = Nanoc::LayoutCollectionView.new(site.layouts)

      assert_equal('This is the /foo/ layout.', render('/foo/'))
    end
  end

  def test_render_with_non_cleaned_identifier
    with_site do |site|
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :erb\n")
      end

      File.open('layouts/foo.erb', 'w') do |io|
        io.write 'This is the <%= @layout.identifier %> layout.'
      end

      @site = Nanoc::SiteView.new(site)
      @layouts = Nanoc::LayoutCollectionView.new(site.layouts)

      assert_equal('This is the /foo/ layout.', render('/foo'))
    end
  end

  def test_render_class
    with_site do |site|
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :erb\n")
      end

      File.open('layouts/foo.erb', 'w') do |io|
        io.write 'I am the <%= @layout.class %> class.'
      end

      @site = Nanoc::SiteView.new(site)
      @layouts = Nanoc::LayoutCollectionView.new(site.layouts)

      assert_equal('I am the Nanoc::LayoutView class.', render('/foo/'))
    end
  end

  def test_render_with_unknown_layout
    with_site do |site|
      @site = Nanoc::SiteView.new(site)
      @layouts = Nanoc::LayoutCollectionView.new(site.layouts)

      assert_raises(Nanoc::Int::Errors::UnknownLayout) do
        render '/dsfghjkl/'
      end
    end
  end

  def test_render_without_filter
    with_site do |site|
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', nil\n")
      end

      File.open('layouts/foo.erb', 'w').close

      @site = Nanoc::SiteView.new(site)
      @layouts = Nanoc::LayoutCollectionView.new(site.layouts)

      assert_raises(Nanoc::Int::Errors::CannotDetermineFilter) do
        render '/foo/'
      end
    end
  end

  def test_render_with_unknown_filter
    with_site do |site|
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :asdf\n")
      end

      File.open('layouts/foo.erb', 'w').close

      @site = Nanoc::SiteView.new(site)
      @layouts = Nanoc::LayoutCollectionView.new(site.layouts)

      assert_raises(Nanoc::Int::Errors::UnknownFilter) do
        render '/foo/'
      end
    end
  end

  def test_render_with_block
    with_site do |site|
      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :erb\n")
      end

      File.open('layouts/foo.erb', 'w') do |io|
        io.write '[partial-before]<%= yield %>[partial-after]'
      end

      @site = Nanoc::SiteView.new(site)
      @layouts = Nanoc::LayoutCollectionView.new(site.layouts)

      _erbout = '[erbout-before]'
      result = render '/foo/' do
        _erbout << 'This is some extra content'
      end

      assert_equal('[erbout-before][partial-before]This is some extra content[partial-after]', _erbout)
      assert_equal '', result
    end
  end
end
