describe Nanoc::Int::Compiler do
  let(:compiler) do
    described_class.new(
      site,
      compiled_content_cache: compiled_content_cache,
      checksum_store: checksum_store,
      rule_memory_store: rule_memory_store,
      action_provider: action_provider,
      dependency_store: dependency_store,
      outdatedness_checker: outdatedness_checker,
      reps: reps,
    )
  end

  let(:checksum_store)         { :__irrelevant_checksum_store }
  let(:rule_memory_store)      { :__irrelevant_rule_memory_store }

  let(:dependency_store) { Nanoc::Int::DependencyStore.new(items.to_a) }
  let(:reps) { Nanoc::Int::ItemRepRepo.new }

  let(:outdatedness_checker) { double(:outdatedness_checker) }
  let(:action_provider) { double(:action_provider) }

  let(:compiled_content_cache) { Nanoc::Int::CompiledContentCache.new(items: items) }

  let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Int::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }

  let(:other_rep) { Nanoc::Int::ItemRep.new(other_item, :default) }
  let(:other_item) { Nanoc::Int::Item.new('other content', {}, '/other.md') }

  let(:site) do
    Nanoc::Int::Site.new(
      config: config,
      code_snippets: code_snippets,
      items: items,
      layouts: layouts,
    )
  end

  let(:config) { Nanoc::Int::Configuration.new.with_defaults }
  let(:layouts) { [] }
  let(:code_snippets) { [] }

  let(:items) do
    Nanoc::Int::IdentifiableCollection.new(config).tap do |col|
      col << item
      col << other_item
    end
  end

  let(:memory) do
    [
      Nanoc::Int::ProcessingActions::Filter.new(:erb, {}),
      Nanoc::Int::ProcessingActions::Snapshot.new(:last, nil),
    ]
  end

  before do
    reps << rep
    reps << other_rep

    reps.each do |rep|
      rep.snapshot_defs << Nanoc::Int::SnapshotDef.new(:last, true)
    end

    allow(outdatedness_checker).to receive(:outdated?).with(rep).and_return(true)
    allow(outdatedness_checker).to receive(:outdated?).with(other_rep).and_return(true)

    allow(action_provider).to receive(:memory_for).with(rep).and_return(memory)
    allow(action_provider).to receive(:memory_for).with(other_rep).and_return(memory)
  end

  describe '#compile_reps' do
    subject { compiler.send(:compile_reps) }

    before do
      allow(action_provider).to receive(:snapshots_defs_for).with(rep).and_return(snapshot_defs_for_rep)
      allow(action_provider).to receive(:snapshots_defs_for).with(other_rep).and_return(snapshot_defs_for_rep)
    end

    let(:snapshot_defs_for_rep) do
      [Nanoc::Int::SnapshotDef.new(:last, true)]
    end

    let(:snapshot_defs_for_other_rep) do
      [Nanoc::Int::SnapshotDef.new(:last, true)]
    end

    it 'compiles individual reps' do
      expect { subject }.to change { rep.snapshot_contents[:last].string }
        .from('<%= 1 + 2 %>')
        .to('3')
    end

    context 'exception' do
      let(:item) { Nanoc::Int::Item.new('<%= raise "lol" %>', {}, '/hi.md') }

      it 'wraps exception' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::CompilationError)
      end

      it 'contains the right item rep in the wrapped exception' do
        expect { subject }.to raise_error do |err|
          expect(err.item_rep).to eql(rep)
        end
      end

      it 'contains the right wrapped exception' do
        expect { subject }.to raise_error do |err|
          expect(err.unwrap).to be_a(RuntimeError)
          expect(err.unwrap.message).to eq('lol')
        end
      end
    end
  end

  describe '#compile_rep' do
    subject { compiler.send(:compile_rep, rep, is_outdated: is_outdated) }

    let(:is_outdated) { true }

    it 'generates expected output' do
      expect(rep.snapshot_contents[:last].string).to eql(item.content.string)
      subject
      expect(rep.snapshot_contents[:last].string).to eql('3')
    end

    it 'generates notifications in the proper order' do
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_started, rep, :erb).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :erb).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered

      subject
    end

    context 'interrupted compilation' do
      let(:item) { Nanoc::Int::Item.new('other=<%= @items["/other.*"].compiled_content %>', {}, '/hi.md') }

      before do
        expect(action_provider).to receive(:memory_for).with(other_rep).and_return(memory)
      end

      it 'generates expected output' do
        expect(rep.snapshot_contents[:last].string).to eql(item.content.string)

        expect { compiler.send(:compile_rep, rep, is_outdated: true) }
          .to raise_error(Nanoc::Int::Errors::UnmetDependency)
        compiler.send(:compile_rep, other_rep, is_outdated: true)
        compiler.send(:compile_rep, rep, is_outdated: true)

        expect(rep.snapshot_contents[:last].string).to eql('other=other content')
      end

      it 'generates notifications in the proper order' do
        # rep 1
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_started, rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:dependency_created, item, other_item).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_suspended, rep, anything).ordered

        # rep 2
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, other_rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_started, other_rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_ended, other_rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_ended, other_rep).ordered

        # rep 1 (again)
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered

        expect { compiler.send(:compile_rep, rep, is_outdated: true) }
          .to raise_error(Nanoc::Int::Errors::UnmetDependency)
        compiler.send(:compile_rep, other_rep, is_outdated: true)
        compiler.send(:compile_rep, rep, is_outdated: true)
      end
    end
  end
end
