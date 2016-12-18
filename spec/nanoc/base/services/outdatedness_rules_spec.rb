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

    let(:action_provider) { double(:action_provider) }
    let(:reps) { Nanoc::Int::ItemRepRepo.new }
    let(:dependency_store) { Nanoc::Int::DependencyStore.new(dependency_store_objects) }
    let(:rule_memory_store) { Nanoc::Int::RuleMemoryStore.new }
    let(:checksum_store) { Nanoc::Int::ChecksumStore.new }

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

    context 'NotEnoughData' do
      let(:rule_class) { Nanoc::Int::OutdatednessRules::NotEnoughData }

      context 'item' do
        let(:obj) { item }

        before { reps << item_rep }

        context 'no checksum available' do
          it { is_expected.to be }
        end

        context 'checksum available' do
          before { checksum_store.add(item) }
          it { is_expected.not_to be }
        end
      end

      context 'item rep' do
        let(:obj) { item_rep }

        context 'no checksum available' do
          it { is_expected.to be }
        end

        context 'checksum available' do
          before { checksum_store.add(item) }
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

      let(:old_mem) do
        Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
          mem.add_filter(:erb, {})
          mem.add_snapshot(:donkey, true, '/foo.md')
        end
      end

      before do
        rule_memory_store[item_rep] = old_mem.serialize
        allow(action_provider).to receive(:memory_for).with(item_rep).and_return(new_mem)
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
end
