# frozen_string_literal: true

require 'helper'

class Nanoc::Helpers::LinkToTest < Nanoc::TestCase
  include Nanoc::Helpers::LinkTo

  def setup
    super

    reps = Nanoc::Core::ItemRepRepo.new

    config = Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults

    items = Nanoc::Core::ItemCollection.new(config, [])
    layouts = Nanoc::Core::LayoutCollection.new(config, [])

    site =
      Nanoc::Core::Site.new(
        config: config,
        code_snippets: [],
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )

    compiled_content_cache = Nanoc::Core::CompiledContentCache.new(config: config)
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
        action_provider: action_provider,
        reps: reps,
        site: site,
        compiled_content_cache: compiled_content_cache,
        compiled_content_store: compiled_content_store,
      )

    @view_context =
      Nanoc::Core::ViewContextForCompilation.new(
        reps: reps,
        items: Nanoc::Core::ItemCollection.new(config),
        dependency_tracker: Nanoc::Core::DependencyTracker::Null.new,
        compilation_context: compilation_context,
        compiled_content_store: compiled_content_store,
      )
  end

  def test_examples_link_to
    # Parse
    YARD.parse(LIB_DIR + '/nanoc/helpers/link_to.rb')

    # Mock
    @items = [
      Nanoc::Core::CompilationItemRepView.new(mock, @view_context),
      Nanoc::Core::CompilationItemRepView.new(mock, @view_context),
      Nanoc::Core::CompilationItemRepView.new(mock, @view_context),
    ]
    @items[0].stubs(:identifier).returns('/about/')
    @items[0].stubs(:path).returns('/about.html')
    @items[1].stubs(:identifier).returns('/software/')
    @items[1].stubs(:path).returns('/software.html')
    @items[2].stubs(:identifier).returns('/software/nanoc/')
    @items[2].stubs(:path).returns('/software/nanoc.html')
    about_rep_vcard = Nanoc::Core::CompilationItemRepView.new(mock, @view_context)
    about_rep_vcard.stubs(:path).returns('/about.vcf')
    @items[0].stubs(:rep).with(:vcard).returns(about_rep_vcard)

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#link_to'
  end

  def test_examples_link_to_unless_current
    # Parse
    YARD.parse(LIB_DIR + '/nanoc/helpers/link_to.rb')

    # Mock
    @item_rep = mock
    @item_rep.stubs(:path).returns('/about/')
    @item = mock
    @item.stubs(:path).returns(@item_rep.path)

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#link_to_unless_current'
  end

  def test_examples_relative_path_to
    # Parse
    YARD.parse(LIB_DIR + '/nanoc/helpers/link_to.rb')

    # Mock
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/')

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#relative_path_to'
  end
end
