# frozen_string_literal: true

describe Nanoc::Core::OutdatednessRules do
  Class.new(Nanoc::Core::Filter) do
    identifier :always_outdated_voibwz9nhgf6gbpkdznrxcwkqgzlwnif
    always_outdated

    def run(content, _params)
      content.upcase
    end
  end

  describe '#apply' do
    subject { rule_class.instance.apply(obj, basic_outdatedness_checker) }

    let(:obj) { item_rep }

    let(:basic_outdatedness_checker) do
      Nanoc::Core::BasicOutdatednessChecker.new(
        site:,
        checksum_store:,
        checksums:,
        dependency_store:,
        action_sequence_store:,
        action_sequences:,
        reps:,
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
        config:,
        code_snippets:,
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )
    end

    let(:action_sequences) { {} }
    let(:reps) { Nanoc::Core::ItemRepRepo.new }
    let(:dependency_store) { Nanoc::Core::DependencyStore.new(items, layouts, config) }
    let(:action_sequence_store) { Nanoc::Core::ActionSequenceStore.new(config:) }
    let(:checksum_store) { Nanoc::Core::ChecksumStore.new(config:, objects:) }

    let(:checksums) do
      checksums = {}

      [items, layouts].each do |documents|
        documents.each do |document|
          checksums[[document.reference, :content]] =
            Nanoc::Core::Checksummer.calc_for_content_of(document)
          checksums[[document.reference, :each_attribute]] =
            Nanoc::Core::Checksummer.calc_for_each_attribute_of(document)
        end
      end

      [items, layouts, code_snippets].each do |objs|
        objs.each do |obj|
          checksums[obj.reference] =
            Nanoc::Core::Checksummer.calc(obj)
        end
      end

      checksums[config.reference] =
        Nanoc::Core::Checksummer.calc(config)
      checksums[[config.reference, :each_attribute]] =
        Nanoc::Core::Checksummer.calc_for_each_attribute_of(config)

      Nanoc::Core::ChecksumCollection.new(checksums)
    end

    let(:items) { Nanoc::Core::ItemCollection.new(config, [item]) }
    let(:layouts) { Nanoc::Core::LayoutCollection.new(config, [layout]) }

    before do
      allow(site).to receive_messages(code_snippets:, config:)
    end

    describe 'CodeSnippetsModified' do
      let(:rule_class) { Nanoc::Core::OutdatednessRules::CodeSnippetsModified }

      context 'no snippets' do
        let(:code_snippets) { [] }

        it { is_expected.to be_nil }
      end

      context 'only non-outdated snippets' do
        let(:code_snippet) { Nanoc::Core::CodeSnippet.new('asdf', 'lib/foo.md') }
        let(:code_snippets) { [code_snippet] }

        before { checksum_store.add(code_snippet) }

        it { is_expected.to be_nil }
      end

      context 'only outdated snippets' do
        let(:code_snippet) { Nanoc::Core::CodeSnippet.new('asdf', 'lib/foo.md') }
        let(:code_snippet_old) { Nanoc::Core::CodeSnippet.new('aaaaaaaa', 'lib/foo.md') }
        let(:code_snippets) { [code_snippet] }

        before { checksum_store.add(code_snippet_old) }

        it { is_expected.not_to be_nil }
      end
    end

    describe 'NotWritten' do
      let(:rule_class) { Nanoc::Core::OutdatednessRules::NotWritten }

      context 'no path' do
        before { item_rep.paths = {} }

        it { is_expected.to be_nil }
      end

      context 'path for last snapshot' do
        let(:path) { Dir.getwd + '/output/foo.txt' }

        before { item_rep.raw_paths = { last: [path] } }

        context 'not written' do
          it { is_expected.not_to be_nil }
        end

        context 'written' do
          before do
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, 'hello')
          end

          it { is_expected.to be_nil }
        end
      end

      context 'path for other snapshot' do
        let(:path) { Dir.getwd + '/output/foo.txt' }

        before { item_rep.raw_paths = { donkey: [path] } }

        context 'not written' do
          it { is_expected.not_to be_nil }
        end

        context 'written' do
          before do
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, 'hello')
          end

          it { is_expected.to be_nil }
        end
      end

      context 'path inside output dir not inside current directory' do
        let(:path) { output_dir + '/foo.txt' }

        let(:config) { super().merge(output_dir:) }
        let(:output_dir) { Dir.mktmpdir('nanoc-outdatendess-rules-spec') }

        before { item_rep.raw_paths = { donkey: [path] } }

        context 'not written' do
          it { is_expected.not_to be_nil }
        end

        context 'written' do
          before { File.write(path, 'hello') }

          it { is_expected.to be_nil }
        end
      end
    end

    describe 'ContentModified' do
      let(:rule_class) { Nanoc::Core::OutdatednessRules::ContentModified }

      context 'item' do
        let(:obj) { item }

        before { reps << item_rep }

        context 'no checksum available' do
          it { is_expected.not_to be_nil }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.to be_nil }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be_nil }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be_nil }
        end
      end

      context 'item rep' do
        let(:obj) { item_rep }

        context 'no checksum available' do
          it { is_expected.not_to be_nil }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.to be_nil }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be_nil }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be_nil }
        end
      end
    end

    describe 'AttributesModified' do
      let(:rule_class) { Nanoc::Core::OutdatednessRules::AttributesModified }

      context 'item' do
        let(:obj) { item }

        before { reps << item_rep }

        context 'no checksum available' do
          it { is_expected.not_to be_nil }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.to be_nil }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be_nil }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be_nil }

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
          it { is_expected.not_to be_nil }
        end

        context 'checksum available and same' do
          before { checksum_store.add(item) }

          it { is_expected.to be_nil }
        end

        context 'checksum available, but content different' do
          let(:old_item) { Nanoc::Core::Item.new('other stuff!!!!', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be_nil }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Core::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.not_to be_nil }

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
      let(:rule_class) { Nanoc::Core::OutdatednessRules::RulesModified }

      let(:old_mem) do
        Nanoc::Core::ActionSequenceBuilder.build do |b|
          b.add_filter(:erb, {})
        end
      end

      let(:action_sequences) { { item_rep => new_mem } }

      before do
        action_sequence_store[item_rep] = old_mem.serialize
      end

      context 'memory is the same' do
        let(:new_mem) { old_mem }

        it { is_expected.to be_nil }
      end

      context 'memory is different' do
        let(:new_mem) do
          Nanoc::Core::ActionSequenceBuilder.build do |b|
            b.add_filter(:erb, {})
            b.add_filter(:donkey, {})
          end
        end

        it { is_expected.not_to be_nil }
      end

      context 'memory is the same, but refers to a layout' do
        let(:old_mem) do
          Nanoc::Core::ActionSequenceBuilder.build do |b|
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
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) { new_layout_mem }

          it { is_expected.to be_nil }
        end

        context 'referenced layout does not exist' do
          let(:new_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:haml, {})
            end
          end

          let(:old_mem) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_layout('/moo.*', {})
            end
          end

          # Something changed about the layout; the item-on-layout dependency
          # will ensure this item is marked as outdated.
          it { is_expected.to be_nil }
        end

        context 'filter name is different' do
          let(:new_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:haml, {})
            end
          end

          it { is_expected.not_to be_nil }
        end

        context 'params are different' do
          let(:new_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end
          end

          let(:old_layout_mem) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, foo: 123)
            end
          end

          it { is_expected.not_to be_nil }
        end
      end
    end

    describe 'ContentModified, AttributesModified' do
      subject do
        [
          Nanoc::Core::OutdatednessRules::ContentModified,
          Nanoc::Core::OutdatednessRules::AttributesModified,
        ].map { |c| !!c.instance.apply(new_obj, basic_outdatedness_checker) } # rubocop:disable Style/DoubleNegation
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
      let(:rule_class) { Nanoc::Core::OutdatednessRules::UsesAlwaysOutdatedFilter }

      let(:action_sequences) { { item_rep => mem } }

      context 'unknown filter' do
        let(:mem) do
          Nanoc::Core::ActionSequenceBuilder.build do |b|
            b.add_snapshot(:donkey, '/foo.md', item_rep)
            b.add_filter(:asdf, {})
          end
        end

        it { is_expected.to be_nil }
      end

      context 'known filter, not always outdated' do
        let(:mem) do
          Nanoc::Core::ActionSequenceBuilder.build do |b|
            b.add_snapshot(:donkey, '/foo.md', item_rep)
            b.add_filter(:erb, {})
          end
        end

        it { is_expected.to be_nil }
      end

      context 'known filter, always outdated' do
        let(:mem) do
          Nanoc::Core::ActionSequenceBuilder.build do |b|
            b.add_snapshot(:donkey, '/foo.md', item_rep)
            b.add_filter(:always_outdated_voibwz9nhgf6gbpkdznrxcwkqgzlwnif, {})
          end
        end

        it { is_expected.not_to be_nil }
      end
    end

    describe 'ItemAdded' do
      let(:rule_class) { Nanoc::Core::OutdatednessRules::ItemAdded }

      let(:items_before) do
        Nanoc::Core::ItemCollection.new(config, [old_item])
      end

      let(:items_after) do
        Nanoc::Core::ItemCollection.new(config, [old_item, new_item])
      end

      let(:old_item) { Nanoc::Core::Item.new('stuff', {}, '/old.md') }
      let(:new_item) { Nanoc::Core::Item.new('new', {}, '/new.md') }

      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(items_before, layouts, config).store
        Nanoc::Core::DependencyStore.new(items_after, layouts, config).tap(&:load)
      end

      context 'when used on old item' do
        let(:obj) { Nanoc::Core::ItemRep.new(old_item, :default) }

        example do
          expect(subject).to be_nil
        end
      end

      context 'when used on new item' do
        let(:obj) { Nanoc::Core::ItemRep.new(new_item, :default) }

        example do
          expect(subject).to eq(Nanoc::Core::OutdatednessReasons::DocumentAdded)
        end
      end
    end

    describe 'LayoutAdded' do
      let(:rule_class) { Nanoc::Core::OutdatednessRules::LayoutAdded }

      let(:layouts_before) do
        Nanoc::Core::LayoutCollection.new(config, [old_layout])
      end

      let(:layouts_after) do
        Nanoc::Core::LayoutCollection.new(config, [old_layout, new_layout])
      end

      let(:old_layout) { Nanoc::Core::Layout.new('stuff', {}, '/old.md') }
      let(:new_layout) { Nanoc::Core::Layout.new('new', {}, '/new.md') }

      let(:dependency_store) do
        Nanoc::Core::DependencyStore.new(items, layouts_before, config).store
        Nanoc::Core::DependencyStore.new(items, layouts_after, config).tap(&:load)
      end

      context 'when used on old layout' do
        let(:obj) { old_layout }

        example do
          expect(subject).to be_nil
        end
      end

      context 'when used on new layout' do
        let(:obj) { new_layout }

        example do
          expect(subject).to eq(Nanoc::Core::OutdatednessReasons::DocumentAdded)
        end
      end
    end
  end
end
