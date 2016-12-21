describe Nanoc::Int::OutdatednessRules do
  describe '#apply' do
    subject { rule_class.instance.apply(obj, outdatedness_checker) }

    let(:obj) { item_rep }

    let(:outdatedness_checker) do
      Nanoc::Int::OutdatednessChecker.new(
        site: site,
        checksum_store: checksum_store,
        dependency_store: dependency_store,
        rule_memory_store: rule_memory_store,
        action_provider: action_provider,
        reps: reps,
      )
    end

    let(:item_rep) { Nanoc::Int::ItemRep.new(item, :default) }
    let(:item) { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }

    let(:site) { double(:site) }
    let(:config) { Nanoc::Int::Configuration.new }
    let(:code_snippets) { [] }
    let(:objects) { [config] + code_snippets + [item] }

    let(:action_provider) { double(:action_provider) }
    let(:reps) { Nanoc::Int::ItemRepRepo.new }
    let(:dependency_store) { Nanoc::Int::DependencyStore.new(dependency_store_objects) }
    let(:rule_memory_store) { Nanoc::Int::RuleMemoryStore.new }
    let(:checksum_store) { Nanoc::Int::ChecksumStore.new(objects: objects) }

    let(:dependency_store_objects) { [item] }

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

      context 'only non-outdated snippets' do
        let(:code_snippet) { Nanoc::Int::CodeSnippet.new('asdf', 'lib/foo.md') }
        let(:code_snippet_old) { Nanoc::Int::CodeSnippet.new('aaaaaaaa', 'lib/foo.md') }
        let(:code_snippets) { [code_snippet] }

        before { checksum_store.add(code_snippet_old) }

        it { is_expected.to be }
      end
    end

    context 'ConfigurationModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::ConfigurationModified }

      context 'only non-outdated snippets' do
        let(:config) { Nanoc::Int::CodeSnippet.new('asdf', 'lib/foo.md') }

        before { checksum_store.add(config) }

        it { is_expected.not_to be }
      end

      context 'only non-outdated snippets' do
        let(:config) { Nanoc::Int::Configuration.new }
        let(:config_old) { Nanoc::Int::Configuration.new(hash: { foo: 125 }) }

        before { checksum_store.add(config_old) }

        it { is_expected.to be }
      end
    end

    context 'NotWritten' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::NotWritten }

      context 'no path' do
        before { item_rep.paths = {} }

        it { is_expected.not_to be }
      end

      context 'path' do
        let(:path) { 'foo.txt' }

        before { item_rep.raw_paths = { last: path } }

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
        end
      end
    end

    context 'RulesModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::RulesModified }

      let(:old_mem) do
        Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
          mem.add_filter(:erb, {})
        end
      end

      before do
        rule_memory_store[item_rep] = old_mem.serialize
        allow(action_provider).to receive(:memory_for).with(item_rep).and_return(new_mem)
      end

      context 'memory is the same' do
        let(:new_mem) { old_mem }
        it { is_expected.not_to be }
      end

      context 'memory is different' do
        let(:new_mem) do
          Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_filter(:donkey, {})
          end
        end

        it { is_expected.to be }
      end
    end

    context 'PathsModified' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::PathsModified }

      before do
        allow(action_provider).to receive(:memory_for).with(item_rep).and_return(new_mem)
      end

      context 'old mem does not exist' do
        let(:new_mem) do
          Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
            mem.add_snapshot(:donkey, true, '/foo.md')
            mem.add_filter(:asdf, {})
          end
        end

        it { is_expected.to be }
      end

      context 'old mem exists' do
        let(:old_mem) do
          Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_snapshot(:donkey, true, '/foo.md')
          end
        end

        before do
          rule_memory_store[item_rep] = old_mem.serialize
        end

        context 'paths in memory are the same' do
          let(:new_mem) do
            Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
              mem.add_snapshot(:donkey, true, '/foo.md')
              mem.add_filter(:asdf, {})
            end
          end

          it { is_expected.not_to be }
        end

        context 'paths in memory are different' do
          let(:new_mem) do
            Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
              mem.add_filter(:erb, {})
              mem.add_snapshot(:donkey, true, '/foo.md')
              mem.add_filter(:donkey, {})
              mem.add_snapshot(:giraffe, true, '/bar.md')
            end
          end

          it { is_expected.to be }
        end
      end
    end

    describe '#{Content,Attributes}Modified' do
      subject do
        # TODO: remove negation
        [
          Nanoc::Int::OutdatednessRules::ContentModified,
          Nanoc::Int::OutdatednessRules::AttributesModified,
        ].map { |c| !c.instance.apply(new_obj, outdatedness_checker) }
      end

      let(:stored_obj) { raise 'override me' }
      let(:new_obj)    { raise 'override me' }

      shared_examples 'a document' do
        let(:stored_obj) { klass.new('a', {}, '/foo.md') }
        let(:new_obj)    { stored_obj }

        context 'no checksum data' do
          context 'not stored' do
            it { is_expected.to eql([false, false]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but content changed afterwards' do
              let(:new_obj) { klass.new('aaaaaaaa', {}, '/foo.md') }
              it { is_expected.to eql([false, true]) }
            end

            context 'but attributes changed afterwards' do
              let(:new_obj) { klass.new('a', { animal: 'donkey' }, '/foo.md') }
              it { is_expected.to eql([true, false]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([true, true]) }
            end
          end
        end

        context 'checksum_data' do
          let(:stored_obj) { klass.new('a', {}, '/foo.md', checksum_data: 'cs-data') }
          let(:new_obj)    { stored_obj }

          context 'not stored' do
            it { is_expected.to eql([false, false]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but checksum data afterwards' do
              let(:new_obj) { klass.new('a', {}, '/foo.md', checksum_data: 'cs-data-new') }
              it { is_expected.to eql([false, false]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([true, true]) }
            end
          end
        end

        context 'content_checksum_data' do
          let(:stored_obj) { klass.new('a', {}, '/foo.md', content_checksum_data: 'cs-data') }
          let(:new_obj)    { stored_obj }

          context 'not stored' do
            it { is_expected.to eql([false, false]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but checksum data afterwards' do
              let(:new_obj) { klass.new('a', {}, '/foo.md', content_checksum_data: 'cs-data-new') }
              it { is_expected.to eql([false, true]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([true, true]) }
            end
          end
        end

        context 'attributes_checksum_data' do
          let(:stored_obj) { klass.new('a', {}, '/foo.md', attributes_checksum_data: 'cs-data') }
          let(:new_obj)    { stored_obj }

          context 'not stored' do
            it { is_expected.to eql([false, false]) }
          end

          context 'stored' do
            before { checksum_store.add(stored_obj) }

            context 'but checksum data afterwards' do
              let(:new_obj) { klass.new('a', {}, '/foo.md', attributes_checksum_data: 'cs-data-new') }
              it { is_expected.to eql([true, false]) }
            end

            context 'and unchanged' do
              it { is_expected.to eql([true, true]) }
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
  end
end
