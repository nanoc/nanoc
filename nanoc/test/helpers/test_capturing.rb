# frozen_string_literal: true

require 'helper'

class Nanoc::Helpers::CapturingTest < Nanoc::TestCase
  include Nanoc::Helpers::Capturing

  def item_rep_repo_for(item)
    Nanoc::Core::ItemRepRepo.new.tap do |repo|
      repo << Nanoc::Core::ItemRep.new(item, :default)
    end
  end

  def view_context_for(item)
    config = Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults

    items = Nanoc::Core::ItemCollection.new(config)
    layouts = Nanoc::Core::LayoutCollection.new(config)
    reps = item_rep_repo_for(item)

    site =
      Nanoc::Core::Site.new(
        config:,
        code_snippets: [],
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )

    compiled_content_cache = Nanoc::Core::CompiledContentCache.new(config:)

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
      reps:,
      items:,
      dependency_tracker: Nanoc::Core::DependencyTracker::Null.new,
      compilation_context:,
      compiled_content_store:,
    )
  end

  def compiled_content_store
    @_compiled_content_store ||= Nanoc::Core::CompiledContentStore.new
  end

  def before
    super
    Nanoc::CLI::ErrorHandler.enable
  end

  def test_dependencies
    with_site do |_site|
      # Prepare
      File.write('lib/helpers.rb', 'include Nanoc::Helpers::Capturing')
      File.write('content/includer.erb', '[<%= content_for(@items.find { |i| i.identifier == \'/includee/\' }, :blah) %>]')
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
      end

      # Compile once
      File.write('content/includee.erb', '{<% content_for :blah do %>Old content<% end %>}')
      Nanoc::CLI.run(%w[compile])

      assert_equal '[Old content]', File.read('output/includer/index.html')

      # Compile again
      File.write('content/includee.erb', '{<% content_for :blah do %>New content<% end %>}')
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

    item = Nanoc::Core::Item.new('content', {}, '/asdf')
    view_context = view_context_for(item)
    @item = Nanoc::Core::CompilationItemView.new(item, view_context_for(item))
    @config = Nanoc::Core::ConfigView.new(Nanoc::Core::Configuration.new(dir: Dir.getwd), view_context)

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
      File.write('content/includer.erb', '{<%= render \'partial\', :item => nil %>}')
      File.write('layouts/partial.erb', '[<%= @item.inspect %>-<%= content_for(@items.find { |i| i.identifier == \'/includee/\' }, :blah) %>]')
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
        io.write "layout '*', :erb\n"
      end

      # Compile once
      File.write('content/includee.erb', '{<% content_for :blah do %>Old content<% end %>}')
      Nanoc::CLI.run(%w[compile])

      assert_equal '{[nil-Old content]}', File.read('output/includer/index.html')

      # Compile again
      File.write('content/includee.erb', '{<% content_for :blah do %>New content<% end %>}')
      Nanoc::CLI.run(%w[compile])

      assert_equal '{[nil-New content]}', File.read('output/includer/index.html')
    end
  end

  def test_self
    with_site do |_site|
      File.write('lib/helpers.rb', 'include Nanoc::Helpers::Capturing')

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
      File.write('lib/helpers.rb', 'include Nanoc::Helpers::Capturing')
      File.write('content/includee.erb', '{<% content_for :blah do %>Content<% end %>}')
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do ; filter :erb ; end\n"
        io.write "route '*' do ; item.identifier + 'index.html' ; end\n"
      end

      # Compile once
      File.write('content/includer.erb', 'Old-<%= content_for(@items["/includee/"], :blah) %>')
      Nanoc::CLI.run(%w[compile])

      assert_equal '{}', File.read('output/includee/index.html')
      assert_equal 'Old-Content', File.read('output/includer/index.html')

      # Compile again
      File.write('content/includer.erb', 'New-<%= content_for(@items["/includee/"], :blah) %>')
      Nanoc::CLI.run(%w[compile])

      assert_equal '{}', File.read('output/includee/index.html')
      assert_equal 'New-Content', File.read('output/includer/index.html')
    end
  end
end
