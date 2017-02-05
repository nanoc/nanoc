describe Nanoc::Int::Compiler::Stages::CompileReps do
  let(:stage) do
    described_class.new(
      outdatedness_store: outdatedness_store,
      dependency_store: dependency_store,
      action_provider: action_provider,
      compilation_context: compilation_context,
      compiled_content_cache: compiled_content_cache,
    )
  end

  let(:compilation_context) do
    Nanoc::Int::Compiler::CompilationContext.new(
      action_provider: action_provider,
      reps: reps,
      site: site,
      compiled_content_cache: compiled_content_cache,
      snapshot_repo: snapshot_repo,
    )
  end

  let(:action_provider) { double(:action_provider) }
  let(:reps) { Nanoc::Int::ItemRepRepo.new }
  let(:compiled_content_cache) { Nanoc::Int::CompiledContentCache.new(items: items) }
  let(:snapshot_repo) { Nanoc::Int::SnapshotRepo.new }

  let(:outdatedness_store) { Nanoc::Int::OutdatednessStore.new(site: site, reps: reps) }
  let(:dependency_store) { Nanoc::Int::DependencyStore.new(items.to_a) }

  let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Int::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }

  let(:other_rep) { Nanoc::Int::ItemRep.new(other_item, :default) }
  let(:other_item) { Nanoc::Int::Item.new('other content', {}, '/other.md') }

  let(:site) do
    Nanoc::Int::Site.new(
      config: config,
      code_snippets: code_snippets,
      data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
    )
  end

  let(:config) { Nanoc::Int::Configuration.new.with_defaults }
  let(:layouts) { [] }
  let(:code_snippets) { [] }

  let(:items) do
    Nanoc::Int::IdentifiableCollection.new(
      config,
      [item, other_item],
    )
  end

  let(:memory) do
    actions =
      [
        Nanoc::Int::ProcessingActions::Filter.new(:erb, {}),
        Nanoc::Int::ProcessingActions::Snapshot.new(:last, nil),
      ]

    Nanoc::Int::RuleMemory.new(nil, actions: actions)
  end

  before do
    reps << rep
    reps << other_rep

    reps.each do |rep|
      rep.snapshot_defs << Nanoc::Int::SnapshotDef.new(:last)
    end

    allow(action_provider).to receive(:memory_for).with(rep).and_return(memory)
    allow(action_provider).to receive(:memory_for).with(other_rep).and_return(memory)
  end

  describe '#compile_reps' do
    subject { stage.run }

    before do
      allow(action_provider).to receive(:snapshots_defs_for).with(rep).and_return(snapshot_defs_for_rep)
      allow(action_provider).to receive(:snapshots_defs_for).with(other_rep).and_return(snapshot_defs_for_rep)
    end

    let(:snapshot_defs_for_rep) do
      [Nanoc::Int::SnapshotDef.new(:last)]
    end

    let(:snapshot_defs_for_other_rep) do
      [Nanoc::Int::SnapshotDef.new(:last)]
    end

    context 'rep not in outdatedness store' do
      it 'keeps the item rep out of the outdatedness store' do
        expect(outdatedness_store.include?(rep)).not_to be
        expect { subject }.not_to change { outdatedness_store.include?(rep) }
      end
    end

    context 'rep in outdatedness store' do
      before { outdatedness_store.add(rep) }

      it 'compiles individual reps' do
        expect { subject }.to change { snapshot_repo.get(rep, :last) }
          .from(nil)
          .to(some_textual_content('3'))
      end

      it 'removes the item rep from the outdatedness store' do
        expect { subject }.to change { outdatedness_store.include?(rep) }.from(true).to(false)
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

        it 'keeps the item rep in the outdatedness store' do
          expect(outdatedness_store.include?(rep)).to be
          expect { subject rescue nil }.not_to change { outdatedness_store.include?(rep) }
        end
      end
    end
  end
end
