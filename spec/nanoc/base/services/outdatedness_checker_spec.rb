describe Nanoc::Int::OutdatednessChecker do
  let(:outdatedness_checker) do
    described_class.new(
      site: site,
      checksum_store: checksum_store,
      dependency_store: dependency_store,
      rule_memory_store: rule_memory_store,
      action_provider: action_provider,
      reps: reps,
    )
  end

  let(:site) { double(:site) }
  let(:checksum_store) { double(:checksum_store) }
  let(:dependency_store) { double(:dependency_store) }

  let(:rule_memory_store) do
    Nanoc::Int::RuleMemoryStore.new
  end

  let(:old_memory_for_item_rep) do
    Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
      mem.add_filter(:erb, {})
    end
  end

  let(:new_memory_for_item_rep) { old_memory_for_item_rep }

  let(:action_provider) { double(:action_provider) }

  let(:reps) do
    Nanoc::Int::ItemRepRepo.new
  end

  let(:item_rep) { Nanoc::Int::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }

  before do
    reps << item_rep
    rule_memory_store[item_rep] = old_memory_for_item_rep.serialize

    allow(action_provider).to receive(:memory_for).with(item_rep).and_return(new_memory_for_item_rep)
  end

  describe '#basic_outdatedness_reason_for' do
    subject { outdatedness_checker.send(:basic_outdatedness_reason_for, obj) }

    let(:checksum_store) do
      Nanoc::Int::ChecksumStore.new
    end

    let(:config) { Nanoc::Int::Configuration.new }

    before do
      checksum_store.add(item)

      allow(site).to receive(:code_snippets).and_return([])
      allow(site).to receive(:config).and_return(config)
    end

    context 'with item' do
      let(:obj) { item }

      context 'rule memory differs' do
        let(:new_memory_for_item_rep) do
          Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
            mem.add_filter(:super_erb, {})
          end
        end

        it 'is outdated due to rule differences' do
          expect(subject).to eql(Nanoc::Int::OutdatednessReasons::RulesModified)
        end
      end

      # …
    end

    context 'with item rep' do
      let(:obj) { item_rep }

      context 'rule memory differs' do
        let(:new_memory_for_item_rep) do
          Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
            mem.add_filter(:super_erb, {})
          end
        end

        it 'is outdated due to rule differences' do
          expect(subject).to eql(Nanoc::Int::OutdatednessReasons::RulesModified)
        end
      end

      # …
    end

    context 'with layout' do
      # …
    end
  end

  describe '#outdated_due_to_dependencies?' do
    subject { outdatedness_checker.send(:outdated_due_to_dependencies?, item) }

    let(:dependency_store) do
      Nanoc::Int::DependencyStore.new(objects)
    end

    let(:checksum_store) do
      Nanoc::Int::ChecksumStore.new
    end

    let(:other_item) { Nanoc::Int::Item.new('other stuff', {}, '/other.md') }
    let(:other_item_rep) { Nanoc::Int::ItemRep.new(other_item, :default) }

    let(:config) { Nanoc::Int::Configuration.new }

    let(:objects) { [item, other_item] }

    let(:old_memory_for_other_item_rep) do
      Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
        mem.add_filter(:erb, {})
      end
    end

    let(:new_memory_for_other_item_rep) { old_memory_for_other_item_rep }

    before do
      reps << other_item_rep
      rule_memory_store[other_item_rep] = old_memory_for_other_item_rep.serialize
      checksum_store.add(other_item)
      checksum_store.add(config)

      allow(action_provider).to receive(:memory_for).with(other_item_rep).and_return(new_memory_for_other_item_rep)
      allow(site).to receive(:code_snippets).and_return([])
      allow(site).to receive(:config).and_return(config)
    end

    context 'only attribute dependency' do
      before do
        dependency_store.record_dependency(item, other_item, attributes: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.not_to be }
      end

      context 'attribute + raw content changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'path changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_snapshot(:donkey, true, '/giraffe.txt')
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'only raw content dependency' do
      before do
        dependency_store.record_dependency(item, other_item, raw_content: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.not_to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'attribute + raw content changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'path changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_snapshot(:donkey, true, '/giraffe.txt')
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'only path dependency' do
      before do
        dependency_store.record_dependency(item, other_item, raw_content: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.not_to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'path changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_snapshot(:donkey, true, '/giraffe.txt')
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'attribute + raw content dependency' do
      before do
        dependency_store.record_dependency(item, other_item, attributes: true, raw_content: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'attribute + raw content changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'rules changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_filter(:donkey, {})
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'attribute + other dependency' do
      before do
        dependency_store.record_dependency(item, other_item, attributes: true, path: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end
    end

    context 'other dependency' do
      before do
        dependency_store.record_dependency(item, other_item, path: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end
    end
  end

  describe '#{content,attributes}_checksums_identical?' do
    subject do
      [
        outdatedness_checker.send(:content_checksums_identical?, new_obj),
        outdatedness_checker.send(:attributes_checksums_identical?, new_obj),
      ]
    end

    let(:checksum_store) { Nanoc::Int::ChecksumStore.new }

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
