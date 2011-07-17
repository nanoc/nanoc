# encoding: utf-8

class Nanoc::Helpers::RenderingTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::Rendering

  def test_render
    with_site do |site|
      @site = site

      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :erb\n")
      end

      File.open('layouts/foo.xyz', 'w') do |io|
        io.write 'This is the <%= @layout.identifier %> layout.'
      end

      assert_equal('This is the /foo/ layout.', render('/foo/'))
    end
  end

  def test_render_with_unknown_layout
    with_site do |site|
      @site = site

      assert_raises(Nanoc::Errors::UnknownLayout) do
        render '/dsfghjkl/'
      end
    end
  end

  def test_render_without_filter
    with_site do |site|
      @site = site

      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', nil\n")
      end

      File.open('layouts/foo.xyz', 'w')

      assert_raises(Nanoc::Errors::CannotDetermineFilter) do
        render '/foo/'
      end
    end
  end

  def test_render_with_unknown_filter
    with_site do |site|
      @site = site

      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :asdf\n")
      end

      File.open('layouts/foo.xyz', 'w')

      assert_raises(Nanoc::Errors::UnknownFilter) do
        render '/foo/'
      end
    end
  end

  def test_render_with_block
    with_site do |site|
      @site = site

      File.open('Rules', 'w') do |io|
        io.write("layout '/foo/', :erb\n")
      end

      File.open('layouts/foo.xyz', 'w') do |io|
        io.write '[partial-before]<%= yield %>[partial-after]'
      end

      _erbout = '[erbout-before]'
      result = render '/foo/' do
        _erbout << "This is some extra content"
      end

      assert_equal('[erbout-before][partial-before]This is some extra content[partial-after]', _erbout)
      assert_equal '', result
    end
  end

end
