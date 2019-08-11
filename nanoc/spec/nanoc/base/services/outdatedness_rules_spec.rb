# frozen_string_literal: true

describe Nanoc::Int::OutdatednessRules do
  describe '#apply' do
    subject { rule_class.instance.apply(obj, outdatedness_checker) }

    let(:obj) { item_rep }

    let(:outdatedness_checker) do
      Nanoc::Int::OutdatednessChecker.new(
        site: site,
        checksum_store: checksum_store,
        checksums: checksums,
        dependency_store: dependency_store,
        action_sequence_store: action_sequence_store,
        action_sequences: action_sequences,
        reps: reps,
      )
    end

    let(:item_rep) { Nanoc::Core::ItemRep.new(item, :default) }
    let(:item) { Nanoc::Core::Item.new('stuff', {}, '/foo.md') }
    let(:layout) { Nanoc::Core::Layout.new('layoutz', {}, '/page.erb') }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
    let(:code_snippets) { [] }
    let(:objects) { [config] + code_snippets + [item] }

    let(:site) do
      Nanoc::Core::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )
    end

    let(:action_sequences) { {} }
    let(:reps) { Nanoc::Core::ItemRepRepo.new }
    let(:dependency_store) { Nanoc::Int::DependencyStore.new(items, layouts, config) }
    let(:action_sequence_store) { Nanoc::Core::ActionSequenceStore.new(config: config) }
    let(:checksum_store) { Nanoc::Core::ChecksumStore.new(config: config, objects: objects) }

    let(:checksums) do
      Nanoc::Int::Compiler::Stages::CalculateChecksums.new(
        items: items,
        layouts: layouts,
        code_snippets: code_snippets,
        config: config,
      ).run
    end

    let(:items) { Nanoc::Core::ItemCollection.new(config, [item]) }
    let(:layouts) { Nanoc::Core::LayoutCollection.new(config, [layout]) }

    before do
      allow(site).to receive(:code_snippets).and_return(code_snippets)
      allow(site).to receive(:config).and_return(config)
    end

    describe 'CodeSnippetsModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::CodeSnippetsModified }

      context 'no snippets' do
        let(:code_snippets) { [] }

        it { is_expected.not_to be }
      end

      context 'only non-outdated snippets' do
        let(:code_snippet) { Nanoc::Core::CodeSnippet.new('asdf', 'lib/foo.md') }
        let(:code_snippets) { [code_snippet] }

        before { checksum_store.add(code_snippet) }

        it { is_expected.not_to be }
      end

      context 'only outdated snippets' do
        let(:code_snippet) { Nanoc::Core::CodeSnippet.new('asdf', 'lib/foo.md') }
        let(:code_snippet_old) { Nanoc::Core::CodeSnippet.new('aaaaaaaa', 'lib/foo.md') }
        let(:code_snippets) { [code_snippet] }

        before { checksum_store.add(code_snippet_old) }

        it { is_expected.to be }
      end
    end

    describe 'NotWritten' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::NotWritten }

      context 'no path' do
        before { item_rep.paths = {} }

        it { is_expected.not_to be }
      end

      context 'path for last snapshot' do
        let(:path) { Dir.getwd + '/foo.txt' }

        before { item_rep.raw_paths = { last: [path] } }

        context 'not written' do
          it { is_expected.to be }
        end

        context 'written' do
          before { File.write(path, 'hello') }

          it { is_expected.not_to be }
        end
      end

      context 'path for other snapshot' do
        let(:path) { Dir.getwd + '/foo.txt' }

        before { item_rep.raw_paths = { donkey: [path] } }

        context 'not written' do
          it { is_expected.to be }
        end

        context 'written' do
          before { File.write(path, 'hello') }

          it { is_expected.not_to be }
        end
      end
    end

    describe 'ContentModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::ContentModified }

      context 'item' do
        let(:obj) { item }

        before { reps << item_rep }

        context 'no checksum available' do
          it { is_expected.to be }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.not_to be }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be }
        end
      end

      context 'item rep' do
        let(:obj) { item_rep }

        context 'no checksum available' do
          it { is_expected.to be }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.not_to be }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be }
        end
      end
    end

    describe 'AttributesModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::AttributesModified }

      context 'item' do
        let(:obj) { item }

        before { reps << item_rep }

        context 'no checksum available' do
          it { is_expected.to be }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.not_to be }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end

        context 'attribute kept identical' do
          let(:item)     { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it 'has the one changed attribute' do
            expect(subject).to be_nil
          end
        end

        context 'attribute changed' do
          let(:item)     { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'ho' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end

        context 'attribute deleted' do
          let(:item)     { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
          let(:old_item) { Nanoc::Core::Item.new('stuff', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end

        context 'attribute added' do
          let(:item)     { Nanoc::Core::Item.new('stuff', {}, '/foo.md') }
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end
      end

      context 'item rep' do
        let(:obj) { item_rep }

        context 'no checksum available' do
          it { is_expected.to be }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.not_to be }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end
      end

      context 'config' do
        # TODO
      end
    end

    describe 'RulesModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::RulesModified }

      let(:old_mem) do
        Nanoc::Core::ActionSequenceBuilder.build(item_rep) do |b|
          b.add_filter(:erb, {})
        end
      end

      let(:action_sequences) { { item_rep => new_mem } }

      before do
        action_sequence_store[item_rep] = old_mem.serialize
      end

      context 'memory is the same' do
        let(:new_mem) { old_mem }

        it { is_expected.not_to be }
      end

      context 'memory is different' do
        let(:new_mem) do
          Nanoc::Core::ActionSequenceBuilder.build(item_rep) do |b|
            b.add_filter(:erb, {})
            b.add_filter(:donkey, {})
          end
        end

        it { is_expected.to be }
      end

      context 'memory is the same, but refers to a layout' do
        let(:old_mem) do
          Nanoc::Core::ActionSequenceBuilder.build(item_rep) do |b|
            b.add_layout('/page.*', {})
          end
        end

        let(:new_mem) { old_mem }

        let(:action_sequences) do
          {
            item_rep => new_mem,
            layout => new_layout_mem,
          }
        end

        before do
          action_sequence_store[layout] = old_layout_mem.serialize
        end

        context 'everything is the same' do
          let(:new_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(layout) do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) { new_layout_mem }

          it { is_expected.not_to be }
        end

        context 'referenced layout does not exist' do
          let(:new_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(layout) do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(layout) do |b|
              b.add_filter(:haml, {})
            end
          end

          let(:old_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(item_rep) do |b|
              b.add_layout('/moo.*', {})
            end
          end

          # Something changed about the layout; the item-on-layout dependency
          # will ensure this item is marked as outdated.
          it { is_expected.not_to be }
        end

        context 'filter name is different' do
          let(:new_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(layout) do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(layout) do |b|
              b.add_filter(:haml, {})
            end
          end

          it { is_expected.to be }
        end

        context 'params are different' do
          let(:new_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(layout) do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build(layout) do |b|
              b.add_filter(:erb, foo: 123)
            end
          end

          it { is_expected.to be }
        end
      end
    end

    describe 'ContentModified, AttributesModified' do
      subject do
        [
          Nanoc::Int::OutdatednessRules::ContentModified,
          Nanoc::Int::OutdatednessRules::AttributesModified,
        ].map { |c| !!c.instance.apply(new_obj, outdatedness_checker) } # rubocop:disable Style/DoubleNegation
      end

      let(:stored_obj) { raise 'override me' }
      let(:new_obj)    { raise 'override me' }

      let(:items) { Nanoc::Core::ItemCollection.new(config, [new_obj]) }

      shared_examples 'a document' do
        let(:stored_obj) { klass.new('a', {}, '/foo.md') }
        let(:new_obj)    { stored_obj }

        context 'no checksum data' do
          context 'not stored' do
            it { is_expected.to eql([true, true]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but content changed afterwards' do
              let(:new_obj) { klass.new('aaaaaaaa', {}, '/foo.md') }

              it { is_expected.to eql([true, false]) }
            end

            context 'but attributes changed afterwards' do
              let(:new_obj) { klass.new('a', { animal: 'donkey' }, '/foo.md') }

              it { is_expected.to eql([false, true]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([false, false]) }
            end
          end
        end

        context 'checksum_data' do
          let(:stored_obj) { klass.new('a', {}, '/foo.md', checksum_data: 'cs-data') }
          let(:new_obj)    { stored_obj }

          context 'not stored' do
            it { is_expected.to eql([true, true]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but checksum data afterwards' do
              # NOTE: ignored for attributes!

              let(:new_obj) { klass.new('a', {}, '/foo.md', checksum_data: 'cs-data-new') }

              it { is_expected.to eql([true, false]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([false, false]) }
            end
          end
        end

        context 'content_checksum_data' do
          let(:stored_obj) { klass.new('a', {}, '/foo.md', content_checksum_data: 'cs-data') }
          let(:new_obj)    { stored_obj }

          context 'not stored' do
            it { is_expected.to eql([true, true]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but checksum data afterwards' do
              let(:new_obj) { klass.new('a', {}, '/foo.md', content_checksum_data: 'cs-data-new') }

              it { is_expected.to eql([true, false]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([false, false]) }
            end
          end
        end

        context 'attributes_checksum_data' do
          # NOTE: attributes_checksum_data is ignored!

          let(:stored_obj) { klass.new('a', {}, '/foo.md', attributes_checksum_data: 'cs-data') }
          let(:new_obj)    { stored_obj }

          context 'not stored' do
            it { is_expected.to eql([true, true]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but checksum data afterwards' do
              let(:new_obj) { klass.new('a', {}, '/foo.md', attributes_checksum_data: 'cs-data-new') }

              it { is_expected.to eql([false, false]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([false, false]) }
            end
          end
        end
      end

      context 'item' do
        let(:klass) { Nanoc::Core::Item }

        it_behaves_like 'a document'
      end

      context 'layout' do
        let(:klass) { Nanoc::Core::Layout }

        it_behaves_like 'a document'
      end

      # …
    end

    describe 'UsesAlwaysOutdatedFilter' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::UsesAlwaysOutdatedFilter }

      let(:action_sequences) { { item_rep => mem } }

      context 'unknown filter' do
        let(:mem) do
          Nanoc::Core::ActionSequenceBuilder.build(item_rep) do |b|
            b.add_snapshot(:donkey, '/foo.md')
            b.add_filter(:asdf, {})
          end
        end

        it { is_expected.not_to be }
      end

      context 'known filter, not always outdated' do
        let(:mem) do
          Nanoc::Core::ActionSequenceBuilder.build(item_rep) do |b|
            b.add_snapshot(:donkey, '/foo.md')
            b.add_filter(:erb, {})
          end
        end

        it { is_expected.not_to be }
      end

      context 'known filter, always outdated' do
        let(:mem) do
          Nanoc::Core::ActionSequenceBuilder.build(item_rep) do |b|
            b.add_snapshot(:donkey, '/foo.md')
            b.add_filter(:xsl, {})
          end
        end

        it { is_expected.to be }
      end
    end

    describe 'ItemCollectionExtended' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::ItemCollectionExtended }

      let(:obj) { items }

      context 'no new item added' do
        before do
          expect(dependency_store).to receive(:new_items).and_return([])
        end

        it { is_expected.not_to be }
      end

      context 'new item added' do
        before do
          expect(dependency_store).to receive(:new_items).and_return([item])
        end

        it { is_expected.to be }
      end
    end

    describe 'LayoutCollectionExtended' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::LayoutCollectionExtended }

      let(:obj) { layouts }

      context 'no new layout added' do
        before do
          expect(dependency_store).to receive(:new_layouts).and_return([])
        end

        it { is_expected.not_to be }
      end

      context 'new layout added' do
        before do
          expect(dependency_store).to receive(:new_layouts).and_return([layout])
        end

        it { is_expected.to be }
      end
    end
  end
end
