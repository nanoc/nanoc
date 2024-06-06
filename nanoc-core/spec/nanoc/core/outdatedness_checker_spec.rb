# frozen_string_literal: true

describe Nanoc::Core::OutdatednessChecker do
  Class.new(Nanoc::Core::Filter) do
    identifier :always_outdated_3zh5qfqlqysghkd5ipek8glxzrljrylr
    always_outdated

    def run(content, _params)
      content.upcase
    end
  end

  let(:site) do
    Nanoc::Core::Site.new(
      config: config_after,
      code_snippets: code_snippets_after,
      data_source: Nanoc::Core::InMemoryDataSource.new(items_after_coll, layouts_after_coll),
    )
  end

  let(:config_before) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:config_after) { config_before }

  let(:code_snippet_a_before) { Nanoc::Core::CodeSnippet.new('aaa', 'lib/a.rb') }
  let(:code_snippet_b_before) { Nanoc::Core::CodeSnippet.new('bbb', 'lib/b.rb') }

  let(:code_snippet_a_after) { code_snippet_a_before }
  let(:code_snippet_b_after) { code_snippet_b_before }

  let(:code_snippets_before) { [code_snippet_a_before, code_snippet_b_before] }
  let(:code_snippets_after)  { [code_snippet_a_after, code_snippet_b_after] }

  let(:item_home_before)          { Nanoc::Core::Item.new('Home', {}, '/home.md') }
  let(:item_home_rep_before)      { Nanoc::Core::ItemRep.new(item_home_before, :default) }
  let(:item_articles_before)      { Nanoc::Core::Item.new('Articles', {}, '/articles.html.erb') }
  let(:item_articles_rep_before)  { Nanoc::Core::ItemRep.new(item_articles_before, :default) }
  let(:item_article_a_before)     { Nanoc::Core::Item.new('Article A', {}, '/articles/2019-a.md') }
  let(:item_article_a_rep_before) { Nanoc::Core::ItemRep.new(item_article_a_before, :default) }
  let(:item_article_b_before)     { Nanoc::Core::Item.new('Article B', {}, '/articles/2022-b.md') }
  let(:item_article_b_rep_before) { Nanoc::Core::ItemRep.new(item_article_b_before, :default) }
  let(:item_article_c_before)     { Nanoc::Core::Item.new('Article C', {}, '/articles/2022-c.md') }
  let(:item_article_c_rep_before) { Nanoc::Core::ItemRep.new(item_article_c_before, :default) }

  let(:item_home_after)          { item_home_before }
  let(:item_home_rep_after)      { item_home_rep_before }
  let(:item_articles_after)      { item_articles_before }
  let(:item_articles_rep_after)  { item_articles_rep_before }
  let(:item_article_a_after)     { item_article_a_before }
  let(:item_article_a_rep_after) { item_article_a_rep_before }
  let(:item_article_b_after)     { item_article_b_before }
  let(:item_article_b_rep_after) { item_article_b_rep_before }
  let(:item_article_c_after)     { item_article_c_before }
  let(:item_article_c_rep_after) { item_article_c_rep_before }

  let(:items_before_array) { [item_home_before, item_articles_before, item_article_a_before, item_article_b_before, item_article_c_before] }
  let(:items_after_array)  { [item_home_after, item_articles_after, item_article_a_after, item_article_b_after, item_article_c_after] }
  let(:items_before_coll)  { Nanoc::Core::ItemCollection.new(config_before, items_before_array) }
  let(:items_after_coll)   { Nanoc::Core::ItemCollection.new(config_after, items_after_array) }

  let(:reps) do
    Nanoc::Core::ItemRepRepo.new.tap do |rr|
      rr << item_home_rep_after
      rr << item_articles_rep_after
      rr << item_article_a_rep_after
      rr << item_article_b_rep_after
      rr << item_article_c_rep_after
    end
  end

  let(:layout_default_before)       { Nanoc::Core::Layout.new('Default', { kind: 'default' }, '/default.html.erb') }
  let(:layout_articles_before)      { Nanoc::Core::Layout.new('Articles', { kind: 'article' }, '/articles.html.erb') }

  let(:layout_default_after)       { layout_default_before }
  let(:layout_articles_after)      { layout_articles_before }

  let(:layouts_before_array) { [layout_default_before, layout_articles_before] }
  let(:layouts_after_array)  { [layout_default_after, layout_articles_after] }
  let(:layouts_before_coll)  { Nanoc::Core::LayoutCollection.new(config_before, layouts_before_array) }
  let(:layouts_after_coll)   { Nanoc::Core::LayoutCollection.new(config_after, layouts_after_array) }

  let(:outdatedness_checker) do
    described_class.new(
      site:,
      checksum_store:,
      checksums: checksums_after,
      dependency_store:,
      action_sequence_store:,
      action_sequences: action_sequences_after,
      reps:,
    )
  end

  let(:checksum_store) do
    Nanoc::Core::ChecksumStore.new(
      config: config_before,
      objects: items_before_array + layouts_before_array,
    ).tap do |store|
      store.checksums = checksums_before.to_h
    end
  end

  let(:checksums_before) do
    Nanoc::Core::CompilationStages::CalculateChecksums.new(
      items: items_before_coll,
      layouts: layouts_before_coll,
      code_snippets: code_snippets_before,
      config: config_before,
    ).run
  end

  let(:checksums_after) do
    Nanoc::Core::CompilationStages::CalculateChecksums.new(
      items: items_after_coll,
      layouts: layouts_after_coll,
      code_snippets: code_snippets_after,
      config: config_after,
    ).run
  end

  let(:dependency_store) do
    # NOTE: No dependencies to start with, but those will be filled in on an
    # ad-hoc basis.
    Nanoc::Core::DependencyStore.new(
      items_before_coll,
      layouts_before_coll,
      config_before,
    )
  end

  let(:action_sequence_store) do
    Nanoc::Core::ActionSequenceStore.new(config: config_before).tap do |store|
      action_sequences_before.each_pair do |obj, action_sequence|
        store[obj] = action_sequence.serialize
      end
    end
  end

  let(:action_sequences_before) do
    {
      item_home_rep_before => some_action_sequence_for_item_rep,
      item_articles_rep_before => some_action_sequence_for_item_rep,
      item_article_a_rep_before => some_action_sequence_for_item_rep,
      item_article_b_rep_before => some_action_sequence_for_item_rep,
      item_article_c_rep_before => some_action_sequence_for_item_rep,

      layout_default_before => some_action_sequence_for_layout,
      layout_articles_before => some_action_sequence_for_layout,
    }
  end

  let(:action_sequences_after) { action_sequences_before }

  let(:some_action_sequence_for_item_rep) do
    Nanoc::Core::ActionSequenceBuilder.build do |b|
      b.add_filter(:erb, {})
    end
  end

  let(:some_action_sequence_for_layout) do
    Nanoc::Core::ActionSequenceBuilder.build do |b|
      b.add_filter(:erb, {})
    end
  end

  let(:different_action_sequence_for_item_rep) do
    Nanoc::Core::ActionSequenceBuilder.build do |b|
      b.add_filter(:xyzzy, {})
    end
  end

  let(:different_action_sequence_for_layout) do
    Nanoc::Core::ActionSequenceBuilder.build do |b|
      b.add_filter(:xyzzy, {})
    end
  end

  let(:always_outdated_action_sequence_for_item_rep) do
    Nanoc::Core::ActionSequenceBuilder.build do |b|
      b.add_filter(:always_outdated_3zh5qfqlqysghkd5ipek8glxzrljrylr, {})
    end
  end

  let(:always_outdated_action_sequence_for_layout) do
    Nanoc::Core::ActionSequenceBuilder.build do |b|
      b.add_filter(:always_outdated_3zh5qfqlqysghkd5ipek8glxzrljrylr, {})
    end
  end

  context 'when nothing has changed' do
    it 'marks all items as NOT outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
    end
  end

  context 'when home item has changed content' do
    let(:item_home_after)          { Nanoc::Core::Item.new('Home UPDATED', {}, '/home.md') }
    let(:item_home_rep_after)      { Nanoc::Core::ItemRep.new(item_home_after, :default) }

    it 'marks home item as outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::ContentModified)
    end

    it 'marks other items as NOT outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
    end
  end

  context 'when article item has changed raw content' do
    let(:item_article_a_after)     { Nanoc::Core::Item.new('Article A UPDATED', {}, '/articles/2019-a.md') }
    let(:item_article_a_rep_after) { Nanoc::Core::ItemRep.new(item_article_a_after, :default) }

    context 'when articles item depends on raw content of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, raw_content: true)
          store.record_dependency(item_articles_before, item_article_b_before, raw_content: true)
          store.record_dependency(item_articles_before, item_article_c_before, raw_content: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::ContentModified)
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on attributes of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, attributes: true)
          store.record_dependency(item_articles_before, item_article_b_before, attributes: true)
          store.record_dependency(item_articles_before, item_article_c_before, attributes: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::ContentModified)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on compiled content of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, compiled_content: true)
          store.record_dependency(item_articles_before, item_article_b_before, compiled_content: true)
          store.record_dependency(item_articles_before, item_article_c_before, compiled_content: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::ContentModified)
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on path of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, path: true)
          store.record_dependency(item_articles_before, item_article_b_before, path: true)
          store.record_dependency(item_articles_before, item_article_c_before, path: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::ContentModified)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end
  end

  context 'when article item has changed attributes' do
    let(:item_article_a_after)     { Nanoc::Core::Item.new('Article A', { title: 'UPDATED title' }, '/articles/2019-a.md') }
    let(:item_article_a_rep_after) { Nanoc::Core::ItemRep.new(item_article_a_after, :default) }

    context 'when articles item depends on raw content of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, raw_content: true)
          store.record_dependency(item_articles_before, item_article_b_before, raw_content: true)
          store.record_dependency(item_articles_before, item_article_c_before, raw_content: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::AttributesModified)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a generic attributes dependency on articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, attributes: true)
          store.record_dependency(item_articles_before, item_article_b_before, attributes: true)
          store.record_dependency(item_articles_before, item_article_c_before, attributes: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::AttributesModified)
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attributes dependency on articles, and is triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, attributes: [:title])
          store.record_dependency(item_articles_before, item_article_b_before, attributes: [:title])
          store.record_dependency(item_articles_before, item_article_c_before, attributes: [:title])
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::AttributesModified)
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attributes dependency on articles, but is not triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, attributes: [:updated_on])
          store.record_dependency(item_articles_before, item_article_b_before, attributes: [:updated_on])
          store.record_dependency(item_articles_before, item_article_c_before, attributes: [:updated_on])
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::AttributesModified)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on compiled content of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, compiled_content: true)
          store.record_dependency(item_articles_before, item_article_b_before, compiled_content: true)
          store.record_dependency(item_articles_before, item_article_c_before, compiled_content: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::AttributesModified)
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on path of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, path: true)
          store.record_dependency(item_articles_before, item_article_b_before, path: true)
          store.record_dependency(item_articles_before, item_article_c_before, path: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::AttributesModified)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end
  end

  context 'when layout has changed raw content' do
    let(:layout_default_after) { Nanoc::Core::Layout.new('Default UPDATED', { kind: 'default' }, '/default.html.erb') }

    context 'when articles item depends on raw content of layout' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, raw_content: true)
        end
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a generic attributes dependency on layout' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, attributes: true)
        end
      end

      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attributes dependency on layout, and is triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, attributes: [:title])
        end
      end

      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attributes dependency on articles, but is not triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, attributes: [:author])
        end
      end

      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when home item has a transitive dependency via articles item on layout' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_home_before, item_articles_before, compiled_content: true)
          store.record_dependency(item_articles_before, layout_default_after, raw_content: true)
        end
      end

      it 'marks home item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end
  end

  context 'when layout has changed attributes' do
    let(:layout_default_after) { Nanoc::Core::Layout.new('Default', { title: 'Title UPDATED' }, '/default.html.erb') }

    context 'when articles item depends on raw content of layout' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, raw_content: true)
        end
      end

      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a generic attributes dependency on layout' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, attributes: true)
        end
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attributes dependency on layout, and is triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, attributes: [:title])
        end
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attributes dependency on articles, but is not triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, layout_default_after, attributes: [:author])
        end
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end
  end

  context 'when article item has changed rules' do
    let(:item_article_a_after)     { Nanoc::Core::Item.new('Article A', {}, '/articles/2019-a.md') }
    let(:item_article_a_rep_after) { Nanoc::Core::ItemRep.new(item_article_a_after, :default) }

    let(:action_sequences_after) do
      action_sequences_before.merge(
        {
          item_article_a_rep_before => different_action_sequence_for_item_rep,
        },
      )
    end

    context 'when articles item depends on raw content of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, raw_content: true)
          store.record_dependency(item_articles_before, item_article_b_before, raw_content: true)
          store.record_dependency(item_articles_before, item_article_c_before, raw_content: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::RulesModified)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on attributes of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, attributes: true)
          store.record_dependency(item_articles_before, item_article_b_before, attributes: true)
          store.record_dependency(item_articles_before, item_article_c_before, attributes: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::RulesModified)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on compiled content of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, compiled_content: true)
          store.record_dependency(item_articles_before, item_article_b_before, compiled_content: true)
          store.record_dependency(item_articles_before, item_article_c_before, compiled_content: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::RulesModified)
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item depends on path of articles' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, item_article_a_before, path: true)
          store.record_dependency(item_articles_before, item_article_b_before, path: true)
          store.record_dependency(item_articles_before, item_article_c_before, path: true)
        end
      end

      it 'marks article item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::RulesModified)
      end

      it 'marks articles item as outdated' do
        # FIXME: This is not optimal. The path has not changed, and so the
        # articles item should not be considered as outdated. This is because
        # the `RulesModified` outdatedness reason has the property `path: true`.

        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty

        # FIXME: This is not optimal. Also see related test case above.
        # expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
      end
    end
  end

  context 'when code snippets are changed' do
    let(:code_snippet_b_after) { Nanoc::Core::CodeSnippet.new('bbb UPDATED', 'lib/b.rb') }

    it 'marks all items as outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::CodeSnippetsModified)
      expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::CodeSnippetsModified)
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::CodeSnippetsModified)
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::CodeSnippetsModified)
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::CodeSnippetsModified)
    end
  end

  context 'when using an always-outdated filter' do
    # NOTE: This modifies both before AND after action sequences.
    let(:action_sequences_before) do
      super().merge(
        {
          item_article_a_rep_before => always_outdated_action_sequence_for_item_rep,
        },
      )
    end

    it 'marks article item as outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::UsesAlwaysOutdatedFilter)
    end

    it 'marks other items as NOT outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
    end
  end

  context 'when path is present but not written' do
    before do
      item_article_a_rep_after.raw_paths = {
        last: ["#{site.config.output_dir}/articles.html"],
      }
    end

    it 'marks article item as outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::NotWritten)
    end

    it 'marks other items as NOT outdated' do
      expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
      expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
    end
  end

  context 'when config has changed' do
    let(:config_after) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { name: 'Name UPDATED' }).with_defaults }

    context 'when there are no dependencies on the config' do
      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a generic attribute dependency on config' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, config_before, attributes: true)
        end
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attribute dependency on config, and is triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, config_before, attributes: [:name])
        end
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attribute dependency on config, but is not triggered' do
      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        ).tap do |store|
          store.record_dependency(item_articles_before, config_before, attributes: [:author])
        end
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end
  end

  context 'when an item is added to the site' do
    let(:item_article_d_after)     { Nanoc::Core::Item.new('Article D', { kind: 'article' }, '/articles/2022-d.md') }
    let(:item_article_d_rep_after) { Nanoc::Core::ItemRep.new(item_article_d_after, :default) }

    let(:items_after_array) { super() + [item_article_d_after] }

    let(:reps) do
      super().tap do |rr|
        rr << item_article_d_rep_after
      end
    end

    let(:action_sequences_after) do
      super().merge(
        {
          item_article_d_rep_after => some_action_sequence_for_item_rep,
        },
      )
    end

    context 'when there are no dependencies on the new item' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end

      it 'marks new item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).not_to be_empty

        # FIXME: It should be DocumentAdded (though it’s not a big issue)
        # expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).to match_array([
        #   Nanoc::Core::OutdatednessReasons::DocumentAdded,
        # ])
      end
    end

    # NOTE: Generic attribute dependency on item collection is not an option,
    # and not needed. IdentifiableCollectionView generates dependencies with
    # specific attributes only.

    context 'when articles item has a specific attribute dependency on all items, and attribute matches' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, items_before_coll, attributes: { kind: 'article' })
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks new item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).not_to be_empty

        # FIXME: It should be DocumentAdded:
        # expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).to match_array([
        #   Nanoc::Core::OutdatednessReasons::DocumentAdded,
        # ])
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attribute dependency on all items, and attribute does not match' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, items_before_coll, attributes: { kind: 'non-article' })
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks new item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).not_to be_empty

        # FIXME: It should be DocumentAdded:
        # expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).to match_array([
        #   Nanoc::Core::OutdatednessReasons::DocumentAdded,
        # ])
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a generic raw content dependency on all items' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, items_before_coll, raw_content: true)
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks new item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).not_to be_empty

        # FIXME: It should be DocumentAdded:
        # expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).to match_array([
        #   Nanoc::Core::OutdatednessReasons::DocumentAdded,
        # ])
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific raw content dependency (string pattern) on all items' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, items_before_coll, raw_content: ['/articles/*.md'])
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks new item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).not_to be_empty

        # FIXME: It should be DocumentAdded:
        # expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).to match_array([
        #   Nanoc::Core::OutdatednessReasons::DocumentAdded,
        # ])
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific raw content dependency (regex pattern) on all items' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, items_before_coll, raw_content: [%r{^/articles/.*}])
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks new item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).not_to be_empty

        # FIXME: It should be DocumentAdded:
        # expect(outdatedness_checker.outdatedness_reasons_for(item_article_d_after)).to match_array([
        #   Nanoc::Core::OutdatednessReasons::DocumentAdded,
        # ])
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end
  end

  context 'when a layout is added to the site' do
    let(:layout_new_after) { Nanoc::Core::Layout.new('Layout', { kind: 'article' }, '/articles/2022-d.md') }

    let(:layouts_after_array) { super() + [layout_new_after] }

    let(:action_sequences_after) do
      super().merge(
        {
          layout_new_after => some_action_sequence_for_layout,
        },
      )
    end

    context 'when there are no dependencies on the new item' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attribute dependency on all layouts, and attribute matches' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, layouts_before_coll, attributes: { kind: 'article' })
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific attribute dependency on all layouts, but attribute does not match' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, layouts_before_coll, attributes: { kind: 'note' })
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks all items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a generic raw content dependency on all layouts' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, layouts_before_coll, raw_content: true)
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific raw content dependency (string pattern) on all layouts' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, layouts_before_coll, raw_content: ['/articles/*.md'])
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end

    context 'when articles item has a specific raw content dependency (regex pattern) on all layouts' do
      before do
        # Store old dependency store
        old_dependency_store = Nanoc::Core::DependencyStore.new(
          items_before_coll,
          layouts_before_coll,
          config_before,
        )
        old_dependency_store.record_dependency(item_articles_before, layouts_before_coll, raw_content: [%r{^/articles/.*}])
        old_dependency_store.store

        # Reload
        dependency_store.items = items_after_coll
        dependency_store.layouts = layouts_after_coll
        dependency_store.load
      end

      it 'marks articles item as outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_articles_after)).to contain_exactly(Nanoc::Core::OutdatednessReasons::DependenciesOutdated)
      end

      it 'marks other items as NOT outdated' do
        expect(outdatedness_checker.outdatedness_reasons_for(item_home_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_a_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_b_after)).to be_empty
        expect(outdatedness_checker.outdatedness_reasons_for(item_article_c_after)).to be_empty
      end
    end
  end

  # NOTE: When an item or layout is removed from the site, the dependency on the
  # item/layout collection will not trigger outdatedness. If any specific item
  # in the collection is used, then that will create individual dependencies.
  #
  # Open questions:
  # - What if you do only do `@items.find_all('/articles/*').size`?
end
