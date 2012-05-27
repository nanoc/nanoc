# encoding: utf-8

class Nanoc::Helpers::CapturingTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::Capturing

  def test_content_for
    require 'erb'

    File.open('Rules', 'w') do |io|
      io.write "compile '*' do ; filter :erb ; end\n"
      io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
    end

    # Build content to be evaluated
    content = "head <% content_for :sidebar do %>\n" +
              "  <%= 1+2 %>\n" +
              "<% end %> foot"

    # Build site
    @site = Nanoc3::Site.new({})
    @item = Nanoc::Item.new('moo', {}, '/blah/')
    @item.site = @site

    # Evaluate content
    result = ::ERB.new(content).result(binding)

    # Check
    assert_equal '3', content_for(@item, :sidebar).strip
    assert_equal '3', @item[:content_for_sidebar].strip
    assert_match(/^head\s+foot$/, result)
  end

  def test_capture
    require 'erb'

    # Build site
    @site = Nanoc3::Site.new({})
    @item = Nanoc::Item.new('moo', {}, '/blah/')

    # Capture
    _erbout = 'foo'
    captured_content = capture do
      _erbout << 'bar'
    end

    # Check
    assert_equal 'foo', _erbout
    assert_equal 'bar', captured_content
  end

  def test_content_for_recursively
    require 'erb'

    File.open('Rules', 'w') do |io|
      io.write "compile '*' do ; filter :erb ; end\n"
      io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
    end

    content = <<EOS
head
<% content_for :box do %>
  basic
<% end %>
<% content_for :box do %>
  before <%= content_for @item, :box %> after
<% end %>
<%= content_for @item, :box %>
foot
EOS

    @site = Nanoc3::Site.new({})
    @item = Nanoc::Item.new('content', {}, '/')

    result = ::ERB.new(content).result(binding)

    expected = %w( head before basic after foot )
    actual   = result.scan(/[a-z]+/)
    assert_equal expected, actual
  end

  def test_different_sites
    require 'erb'

    File.open('Rules', 'w') do |io|
      io.write "compile '*' do ; filter :erb ; end\n"
      io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
    end

    @site = Nanoc3::Site.new({})
    @item = Nanoc::Item.new('content', {}, '/')
    content = "<% content_for :a do %>Content One<% end %>"
    ::ERB.new(content).result(binding)

    assert_equal 'Content One', content_for(@item, :a)
    assert_equal nil,           content_for(@item, :b)

    @site = Nanoc3::Site.new({})
    @item = Nanoc::Item.new('content', {}, '/')
    content = "<% content_for :b do %>Content Two<% end %>"
    ::ERB.new(content).result(binding)

    assert_equal nil,           content_for(@item, :a)
    assert_equal 'Content Two', content_for(@item, :b)
  end

  def test_dependencies
    with_site do |site|
      # Prepare
      File.open('lib/helpers.rb', 'w') do |io|
        io.write 'include Nanoc::Helpers::Capturing'
      end
      File.open('content/includer.erb', 'w') do |io|
        io.write '[<%= content_for(@items.find { |i| i.identifier == \'/includee/\' }, :blah) %>]'
      end
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
      end

      # Compile once
      File.open('content/includee.erb', 'w') do |io|
        io.write '{<% content_for :blah do %>Old content<% end %>}'
      end
      Nanoc::CLI.run(%w(compile))
      assert_equal '[Old content]', File.read('output/includer/index.html')

      # Compile again
      File.open('content/includee.erb', 'w') do |io|
        io.write '{<% content_for :blah do %>New content<% end %>}'
      end
      Nanoc::CLI.run(%w(compile))
      assert_equal '[New content]', File.read('output/includer/index.html')
    end
  end

  def test_dependency_without_item_variable
    with_site do |site|
      # Prepare
      File.open('lib/helpers.rb', 'w') do |io|
        io.write "include Nanoc::Helpers::Capturing\n"
        io.write "include Nanoc::Helpers::Rendering\n"
      end
      File.open('content/includer.erb', 'w') do |io|
        io.write '{<%= render \'partial\', :item => nil %>}'
      end
      File.open('layouts/partial.erb', 'w') do |io|
        io.write '[<%= @item.inspect %>-<%= content_for(@items.find { |i| i.identifier == \'/includee/\' }, :blah) %>]'
      end
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
        io.write "layout '*', :erb\n"
      end

      # Compile once
      File.open('content/includee.erb', 'w') do |io|
        io.write '{<% content_for :blah do %>Old content<% end %>}'
      end
      Nanoc::CLI.run(%w(compile))
      assert_equal '{[nil-Old content]}', File.read('output/includer/index.html')

      # Compile again
      File.open('content/includee.erb', 'w') do |io|
        io.write '{<% content_for :blah do %>New content<% end %>}'
      end
      Nanoc::CLI.run(%w(compile))
      assert_equal '{[nil-New content]}', File.read('output/includer/index.html')
    end
  end

  def test_self
    with_site do |site|
      File.open('lib/helpers.rb', 'w') do |io|
        io.write 'include Nanoc::Helpers::Capturing'
      end

      File.open('content/self.erb', 'w') do |io|
        io.write "<% content_for :foo do %>Foo!<% end %>"
        io.write "<%= content_for(@item, :foo) %>"
      end

      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
      end

      Nanoc::CLI.run(%w(compile))
      assert_equal 'Foo!', File.read('output/self/index.html')
    end
  end

  def test_recompile_dependency
    with_site do |site|
      # Prepare
      File.open('lib/helpers.rb', 'w') do |io|
        io.write 'include Nanoc::Helpers::Capturing'
      end
      File.open('content/includee.erb', 'w') do |io|
        io.write '{<% content_for :blah do %>Content<% end %>}'
      end
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
      end

      # Compile once
      File.open('content/includer.erb', 'w') do |io|
        io.write 'Old-<%= content_for(@items.find { |i| i.identifier == \'/includee/\' }, :blah) %>'
      end
      Nanoc::CLI.run(%w(compile))
      assert_equal 'Old-Content', File.read('output/includer/index.html')

      # Compile again
      $LOUD = true
      File.open('content/includer.erb', 'w') do |io|
        io.write 'New-<%= content_for(@items.find { |i| i.identifier == \'/includee/\' }, :blah) %>'
      end
      Nanoc::CLI.run(%w(compile))
      assert_equal 'New-Content', File.read('output/includer/index.html')
    end
  ensure
    $LOUD = false 
  end

end
