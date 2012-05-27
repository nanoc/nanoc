# encoding: utf-8

class Nanoc::Helpers::FilteringTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::Filtering

  def test_filter_simple
    if_have 'rubypants' do
      # Build content to be evaluated
      content = "<p>Foo...</p>\n" +
                "<% filter :rubypants do %>\n" +
                " <p>Bar...</p>\n" +
                "<% end %>\n"

      # Mock item and rep
      @item_rep = mock
      @item_rep.expects(:assigns).returns({})

      # Evaluate content
      result = ::ERB.new(content).result(binding)

      # Check
      assert_match('<p>Foo...</p>',     result)
      assert_match('<p>Bar&#8230;</p>', result)
    end
  end

  def test_filter_with_assigns
    if_have 'rubypants' do
      # Build content to be evaluated
      content = "<p>Foo...</p>\n" +
                "<% filter :erb do %>\n" +
                " <p><%%= @item[:title] %></p>\n" +
                "<% end %>\n"

      # Mock item and rep
      @item = mock
      @item.expects(:[]).with(:title).returns('Bar...')
      @item.expects(:identifier).returns('/blah/')
      @item_rep = mock
      @item_rep.expects(:name).returns('default')
      @item_rep.expects(:assigns).returns({
        :item     => @item,
        :item_rep => @item_rep
      })

      # Evaluate content
      result = ::ERB.new(content).result(binding)

      # Check
      assert_match('<p>Foo...</p>', result)
      assert_match('<p>Bar...</p>', result)
    end
  end

  def test_filter_with_unknown_filter_name
    # Build content to be evaluated
    content = "<p>Foo...</p>\n" +
              "<% filter :askjdflkawgjlkwaheflnvz do %>\n" +
              " <p>Blah blah blah.</p>\n" +
              "<% end %>\n"

    # Evaluate content
    error = assert_raises(Nanoc::Errors::UnknownFilter) do
      ::ERB.new(content).result(binding)
    end
  end

  def test_filter_with_arguments
    if_have 'coderay' do
      # Build content to be evaluated
      content = "<% filter :coderay, :language => 'ruby' do %>\n" +
                "   def some_function ; x = blah.foo ; x.bar 'xyzzy' ; end\n" +
                "<% end %>\n"

      # Mock item and rep
      @item_rep = mock
      @item_rep.expects(:assigns).returns({})

      # Evaluate content
      result = ::ERB.new(content).result(binding)
      assert_match(%r{<span class="keyword">def</span> <span class="function">some_function</span>}, result)
    end
  end

  def test_with_haml
    if_have 'haml' do
      # Build content to be evaluated
      content = "%p Foo.\n" +
                "- filter(:erb) do\n" +
                "  <%= 'abc' + 'xyz' %>\n" +
                "%p Bar.\n"

      # Mock item and rep
      @item_rep = mock
      @item_rep.expects(:assigns).returns({})

      # Evaluate content
      result = ::Haml::Engine.new(content).render(binding)
      assert_match(%r{^<p>Foo.</p>\s*abcxyz\s*<p>Bar.</p>$}, result)
    end
  end

  def test_notifications
    notifications = Set.new
    Nanoc::NotificationCenter.on(:filtering_started) { notifications << :filtering_started }
    Nanoc::NotificationCenter.on(:filtering_ended)   { notifications << :filtering_ended   }

    # Build content to be evaluated
    content = "<% filter :erb do %>\n" +
              "   ... stuff ...\n" +
              "<% end %>\n"

    # Mock item and rep
    @item_rep = mock
    @item_rep.expects(:assigns).returns({})

    ::ERB.new(content).result(binding)

    assert notifications.include?(:filtering_started)
    assert notifications.include?(:filtering_ended)
  end

end
