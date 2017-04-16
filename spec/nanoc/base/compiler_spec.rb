describe Nanoc::Int::Compiler do
  let(:compiler) do
    described_class.new(
      site,
      compiled_content_cache: compiled_content_cache,
      checksum_store: checksum_store,
      action_sequence_store: action_sequence_store,
      action_provider: action_provider,
      dependency_store: dependency_store,
      reps: reps,
      outdatedness_store: outdatedness_store,
    )
  end

  let(:checksum_store) { Nanoc::Int::ChecksumStore.new(objects: items) }
  let(:action_sequence_store) { Nanoc::Int::ActionSequenceStore.new }

  let(:dependency_store) { Nanoc::Int::DependencyStore.new(items, layouts) }
  let(:reps) { Nanoc::Int::ItemRepRepo.new }

  let(:outdatedness_store) { Nanoc::Int::OutdatednessStore.new(site: site, reps: reps) }
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
      data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
    )
  end

  let(:config) { Nanoc::Int::Configuration.new.with_defaults }
  let(:code_snippets) { [] }

  let(:items) do
    Nanoc::Int::IdentifiableCollection.new(config, [item, other_item])
  end

  let(:layouts) do
    Nanoc::Int::IdentifiableCollection.new(config)
  end

  let(:memory) do
    actions =
      [
        Nanoc::Int::ProcessingActions::Filter.new(:erb, {}),
        Nanoc::Int::ProcessingActions::Snapshot.new([:last], []),
      ]

    Nanoc::Int::ActionSequence.new(nil, actions: actions)
  end

  before do
    reps << rep
    reps << other_rep

    reps.each do |rep|
      rep.snapshot_defs << Nanoc::Int::SnapshotDef.new(:last, binary: false)
    end

    # FIXME: eww
    action_sequences = { rep => memory, other_rep => memory }
    compiler.instance_variable_set(:@action_sequences, action_sequences)

    allow(Nanoc::Int::NotificationCenter).to receive(:post)
  end

  describe '#compile_rep' do
    let(:stage) { compiler.send(:compile_reps_stage) }

    subject { stage.send(:compile_rep, rep, is_outdated: is_outdated) }

    let(:is_outdated) { true }

    it 'generates expected output' do
      expect { subject }
        .to change { compiler.snapshot_repo.get(rep, :last) }
        .from(nil)
        .to(some_textual_content('3'))
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

      it 'generates expected output' do
        expect(compiler.snapshot_repo.get(rep, :last)).to be_nil

        expect { stage.send(:compile_rep, rep, is_outdated: true) }
          .to raise_error(Nanoc::Int::Errors::UnmetDependency)
        stage.send(:compile_rep, other_rep, is_outdated: true)
        stage.send(:compile_rep, rep, is_outdated: true)

        expect(compiler.snapshot_repo.get(rep, :last).string).to eql('other=other content')
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

        expect { stage.send(:compile_rep, rep, is_outdated: true) }
          .to raise_error(Nanoc::Int::Errors::UnmetDependency)
        stage.send(:compile_rep, other_rep, is_outdated: true)
        stage.send(:compile_rep, rep, is_outdated: true)
      end
    end
  end
end
