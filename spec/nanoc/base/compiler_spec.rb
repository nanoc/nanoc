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

  let(:compiled_content_cache) { Nanoc::Int::CompiledContentCache.new }

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
      Nanoc::Int::RuleMemoryActions::Filter.new(:erb, {}),
    ]
  end

  before do
    reps << rep
    reps << other_rep

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

    it 'keeps the compilation stack in a good state' do
      expect(compiler.stack).to be_empty
      subject
      expect(compiler.stack).to be_empty
    end

    context 'exception' do
      let(:item) { Nanoc::Int::Item.new('<%= raise "lol" %>', {}, '/hi.md') }

      it 'keeps the compilation stack in a good state' do
        expect(compiler.stack).to be_empty
        expect { subject }.to raise_error(RuntimeError)
        expect(compiler.stack).to eql([rep])
      end
    end

    context 'interrupted compilation' do
      let(:item) { Nanoc::Int::Item.new('other=<%= @items["/other.*"].compiled_content %>', {}, '/hi.md') }

      before do
        expect(outdatedness_checker).to receive(:outdated?).with(other_rep).and_return(true)
        expect(action_provider).to receive(:memory_for).with(other_rep).and_return(memory)
      end

      it 'keeps the compilation stack in a good state' do
        expect(compiler.stack).to be_empty
        subject
        expect(compiler.stack).to be_empty
      end

      context 'exception' do
        let(:item) { Nanoc::Int::Item.new('other=<%= @items["/other.*"].compiled_content %><% raise "lol" %>', {}, '/hi.md') }

        it 'keeps the compilation stack in a good state' do
          expect(compiler.stack).to be_empty
          expect { subject }.to raise_error(RuntimeError)
          expect(compiler.stack).to eql([rep])
        end
      end
    end
  end

  describe '#compile_rep' do
    subject { compiler.send(:compile_rep, rep) }

    it 'generates expected output' do
      expect(rep.snapshot_contents[:last].string).to eql(item.content.string)
      subject
      expect(rep.snapshot_contents[:last].string).to eql('3')
    end

    it 'generates notifications in the proper order' do
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_started, rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_started, rep, :erb).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :erb).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_ended, rep).ordered

      subject
    end

    context 'interrupted compilation' do
      let(:item) { Nanoc::Int::Item.new('other=<%= @items["/other.*"].compiled_content %>', {}, '/hi.md') }

      before do
        expect(outdatedness_checker).to receive(:outdated?).with(other_rep).and_return(true)
        expect(action_provider).to receive(:memory_for).with(other_rep).and_return(memory)
      end

      it 'generates expected output' do
        expect(rep.snapshot_contents[:last].string).to eql(item.content.string)

        expect { compiler.send(:compile_rep, rep) }.to raise_error(Nanoc::Int::Errors::UnmetDependency)
        compiler.send(:compile_rep, other_rep)
        compiler.send(:compile_rep, rep)

        expect(rep.snapshot_contents[:last].string).to eql('other=other content')
      end

      it 'keeps the compilation stack in a good state' do
        expect(compiler.stack).to be_empty

        expect { compiler.send(:compile_rep, rep) }.to raise_error(Nanoc::Int::Errors::UnmetDependency)
        expect(compiler.stack).to be_empty

        compiler.send(:compile_rep, other_rep)
        expect(compiler.stack).to be_empty

        compiler.send(:compile_rep, rep)
        expect(compiler.stack).to be_empty
      end

      it 'generates notifications in the proper order' do
        # rep 1
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_started, rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_started, rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:dependency_created, item, other_item).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_suspended, rep, anything).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_ended, rep).ordered

        # rep 2
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_started, other_rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, other_rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_started, other_rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_ended, other_rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_ended, other_rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_ended, other_rep).ordered

        # rep 1 (again)
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_started, rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:processing_ended, rep).ordered

        expect { compiler.send(:compile_rep, rep) }.to raise_error(Nanoc::Int::Errors::UnmetDependency)
        compiler.send(:compile_rep, other_rep)
        compiler.send(:compile_rep, rep)
      end
    end
  end
end
