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

    let(:item_rep) { Nanoc::Int::ItemRep.new(item, :default) }
    let(:item) { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }

    let(:config) { Nanoc::Int::Configuration.new }
    let(:code_snippets) { [] }
    let(:objects) { [config] + code_snippets + [item] }

    let(:site) do
      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Int::InMemDataSource.new([], []),
      )
    end

    let(:action_sequences) { {} }
    let(:reps) { Nanoc::Int::ItemRepRepo.new }
    let(:dependency_store) { Nanoc::Int::DependencyStore.new(items, layouts, config) }
    let(:action_sequence_store) { Nanoc::Int::ActionSequenceStore.new }
    let(:checksum_store) { Nanoc::Int::ChecksumStore.new(objects: objects) }

    let(:checksums) do
      Nanoc::Int::Compiler::Stages::CalculateChecksums.new(
        items: items,
        layouts: layouts,
        code_snippets: code_snippets,
        config: config,
      ).run
    end

    let(:items) { Nanoc::Int::ItemCollection.new(config, [item]) }
    let(:layouts) { Nanoc::Int::LayoutCollection.new(config) }

    before do
      allow(site).to receive(:code_snippets).and_return(code_snippets)
      allow(site).to receive(:config).and_return(config)
    end

    context 'CodeSnippetsModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::CodeSnippetsModified }

      context 'no snippets' do
        let(:code_snippets) { [] }
        it { is_expected.not_to be }
      end

      context 'only non-outdated snippets' do
        let(:code_snippet) { Nanoc::Int::CodeSnippet.new('asdf', 'lib/foo.md') }
        let(:code_snippets) { [code_snippet] }

        before { checksum_store.add(code_snippet) }

        it { is_expected.not_to be }
      end

      context 'only outdated snippets' do
        let(:code_snippet) { Nanoc::Int::CodeSnippet.new('asdf', 'lib/foo.md') }
        let(:code_snippet_old) { Nanoc::Int::CodeSnippet.new('aaaaaaaa', 'lib/foo.md') }
        let(:code_snippets) { [code_snippet] }

        before { checksum_store.add(code_snippet_old) }

        it { is_expected.to be }
      end
    end

    context 'NotWritten' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::NotWritten }

      context 'no path' do
        before { item_rep.paths = {} }

        it { is_expected.not_to be }
      end

      context 'path for last snapshot' do
        let(:path) { 'foo.txt' }

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
        let(:path) { 'foo.txt' }

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

    context 'ContentModified' do
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
          let(:old_item) { Nanoc::Int::Item.new('other stuff!!!!', {}, '/foo.md') }
          before { checksum_store.add(old_item) }
          it { is_expected.to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
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
          let(:old_item) { Nanoc::Int::Item.new('other stuff!!!!', {}, '/foo.md') }
          before { checksum_store.add(old_item) }
          it { is_expected.to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
          before { checksum_store.add(old_item) }
          it { is_expected.not_to be }
        end
      end
    end

    context 'AttributesModified' do
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
          let(:old_item) { Nanoc::Int::Item.new('other stuff!!!!', {}, '/foo.md') }
          before { checksum_store.add(old_item) }
          it { is_expected.not_to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it { is_expected.to be }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end

        context 'attribute kept identical' do
          let(:item)     { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
          let(:old_item) { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it 'has the one changed attribute' do
            expect(subject).to be_nil
          end
        end

        context 'attribute changed' do
          let(:item)     { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
          let(:old_item) { Nanoc::Int::Item.new('stuff', { greeting: 'ho' }, '/foo.md') }

          before { checksum_store.add(old_item) }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end

        context 'attribute deleted' do
          let(:item)     { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }
          let(:old_item) { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }

          before { checksum_store.add(old_item) }

          it 'has the one changed attribute' do
            expect(subject.attributes).to contain_exactly(:greeting)
          end
        end

        context 'attribute added' do
          let(:item)     { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }
          let(:old_item) { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

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
          let(:old_item) { Nanoc::Int::Item.new('other stuff!!!!', {}, '/foo.md') }
          before { checksum_store.add(old_item) }
          it { is_expected.not_to be }
        end

        context 'checksum available, but attributes different' do
          let(:old_item) { Nanoc::Int::Item.new('stuff', { greeting: 'hi' }, '/foo.md') }

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

    context 'RulesModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::RulesModified }

      let(:old_mem) do
        Nanoc::Int::ActionSequence.build(item_rep) do |b|
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
          Nanoc::Int::ActionSequence.build(item_rep) do |b|
            b.add_filter(:erb, {})
            b.add_filter(:donkey, {})
          end
        end

        it { is_expected.to be }
      end
    end

    describe '#{Content,Attributes}Modified' do
      subject do
        [
          Nanoc::Int::OutdatednessRules::ContentModified,
          Nanoc::Int::OutdatednessRules::AttributesModified,
        ].map { |c| !!c.instance.apply(new_obj, outdatedness_checker) } # rubocop:disable Style/DoubleNegation
      end

      let(:stored_obj) { raise 'override me' }
      let(:new_obj)    { raise 'override me' }

      let(:items) { [new_obj] }

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
        let(:klass) { Nanoc::Int::Item }
        it_behaves_like 'a document'
      end

      context 'layout' do
        let(:klass) { Nanoc::Int::Layout }
        it_behaves_like 'a document'
      end

      # …
    end

    describe 'UsesAlwaysOutdatedFilter' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::UsesAlwaysOutdatedFilter }

      let(:action_sequences) { { item_rep => mem } }

      context 'unknown filter' do
        let(:mem) do
          Nanoc::Int::ActionSequence.build(item_rep) do |b|
            b.add_snapshot(:donkey, '/foo.md')
            b.add_filter(:asdf, {})
          end
        end

        it { is_expected.not_to be }
      end

      context 'known filter, not always outdated' do
        let(:mem) do
          Nanoc::Int::ActionSequence.build(item_rep) do |b|
            b.add_snapshot(:donkey, '/foo.md')
            b.add_filter(:erb, {})
          end
        end

        it { is_expected.not_to be }
      end

      context 'known filter, always outdated' do
        let(:mem) do
          Nanoc::Int::ActionSequence.build(item_rep) do |b|
            b.add_snapshot(:donkey, '/foo.md')
            b.add_filter(:xsl, {})
          end
        end

        it { is_expected.to be }
      end
    end
  end
end
