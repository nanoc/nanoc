# frozen_string_literal: true

require 'helper'

class Nanoc::Helpers::CapturingTest < Nanoc::TestCase
  include Nanoc::Helpers::Capturing

  def item_rep_repo_for(item)
    Nanoc::Int::ItemRepRepo.new.tap do |repo|
      repo << Nanoc::Int::ItemRep.new(item, :default)
    end
  end

  def view_context_for(item)
    Nanoc::ViewContext.new(
      reps: item_rep_repo_for(item),
      items: :__irrelevant__,
      dependency_tracker: :__irrelevant__,
      compilation_context: :__irrelevant__,
      snapshot_repo: snapshot_repo,
    )
  end

  def snapshot_repo
    @_snapshot_repo ||= Nanoc::Int::SnapshotRepo.new
  end

  def before
    super
    Nanoc::CLI::ErrorHandler.enable
  end

  def test_dependencies
    with_site do |_site|
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
      Nanoc::CLI.run(%w[compile])
      assert_equal '[Old content]', File.read('output/includer/index.html')

      # Compile again
      File.open('content/includee.erb', 'w') do |io|
        io.write '{<% content_for :blah do %>New content<% end %>}'
      end
      Nanoc::CLI.run(%w[compile])
      assert_equal '[New content]', File.read('output/includer/index.html')
    end
  end

  def test_content_for_recursively
    require 'erb'

    File.open('Rules', 'w') do |io|
      io.write "compile '*' do ; filter :erb ; end\n"
      io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
    end

    content = <<~EOS
      head
      <% content_for :box do %>
        basic
      <% end %>
      <% content_for :outerbox do %>
        before <%= content_for @item, :box %> after
      <% end %>
      <%= content_for @item, :outerbox %>
      foot
EOS

    item = Nanoc::Int::Item.new('content', {}, '/')
    view_context = view_context_for(item)
    @item = Nanoc::ItemWithRepsView.new(item, view_context_for(item))
    @config = Nanoc::ConfigView.new(Nanoc::Int::Configuration.new, view_context)

    result = ::ERB.new(content).result(binding)

    expected = %w[head before basic after foot]
    actual   = result.scan(/[a-z]+/)
    assert_equal expected, actual
  end

  def test_dependency_without_item_variable
    with_site do |_site|
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
      Nanoc::CLI.run(%w[compile])
      assert_equal '{[nil-Old content]}', File.read('output/includer/index.html')

      # Compile again
      File.open('content/includee.erb', 'w') do |io|
        io.write '{<% content_for :blah do %>New content<% end %>}'
      end
      Nanoc::CLI.run(%w[compile])
      assert_equal '{[nil-New content]}', File.read('output/includer/index.html')
    end
  end

  def test_self
    with_site do |_site|
      File.open('lib/helpers.rb', 'w') do |io|
        io.write 'include Nanoc::Helpers::Capturing'
      end

      File.open('content/self.erb', 'w') do |io|
        io.write '<% content_for :foo do %>Foo!<% end %>'
        io.write '<%= content_for(@item, :foo) %>'
      end

      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
      end

      Nanoc::CLI.run(%w[compile])
      assert_equal 'Foo!', File.read('output/self/index.html')
    end
  end

  def test_recompile_dependency
    with_site do |_site|
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
        io.write 'Old-<%= content_for(@items["/includee/"], :blah) %>'
      end
      Nanoc::CLI.run(%w[compile])
      assert_equal '{}', File.read('output/includee/index.html')
      assert_equal 'Old-Content', File.read('output/includer/index.html')

      # Compile again
      File.open('content/includer.erb', 'w') do |io|
        io.write 'New-<%= content_for(@items["/includee/"], :blah) %>'
      end
      Nanoc::CLI.run(%w[compile])
      assert_equal '{}', File.read('output/includee/index.html')
      assert_equal 'New-Content', File.read('output/includer/index.html')
    end
  end
end
