# frozen_string_literal: true

describe Nanoc::Int::Compiler do
  let(:compiler) do
    described_class.new(
      site,
      compiled_content_cache: compiled_content_cache,
      checksum_store: checksum_store,
      action_sequence_store: action_sequence_store,
      action_provider: action_provider,
      dependency_store: dependency_store,
      outdatedness_store: outdatedness_store,
    )
  end

  let(:checksum_store) { Nanoc::Int::ChecksumStore.new(config: config, objects: items) }
  let(:action_sequence_store) { Nanoc::Int::ActionSequenceStore.new(config: config) }

  let(:dependency_store) { Nanoc::Int::DependencyStore.new(items, layouts, config) }

  let(:outdatedness_store) { Nanoc::Int::OutdatednessStore.new(config: config) }
  let(:action_provider) { double(:action_provider) }

  let(:compiled_content_cache) do
    Nanoc::Int::CompiledContentCache.new(config: config)
  end

  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Core::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }

  let(:other_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }
  let(:other_item) { Nanoc::Core::Item.new('other content', {}, '/other.md') }

  let(:site) do
    Nanoc::Int::Site.new(
      config: config,
      code_snippets: code_snippets,
      data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
    )
  end

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:code_snippets) { [] }

  let(:items) do
    Nanoc::Core::ItemCollection.new(config, [item, other_item])
  end

  let(:layouts) do
    Nanoc::Core::LayoutCollection.new(config)
  end

  let(:memory) do
    actions =
      [
        Nanoc::Core::ProcessingActions::Filter.new(:erb, {}),
        Nanoc::Core::ProcessingActions::Snapshot.new([:last], []),
      ]

    Nanoc::Int::ActionSequence.new(nil, actions: actions)
  end

  let(:action_sequences) do
    { rep => memory, other_rep => memory }
  end

  before do
    allow(Nanoc::Core::NotificationCenter).to receive(:post)
  end

  describe '#compile_rep' do
    let(:stage) { compiler.send(:compile_reps_stage, action_sequences, reps) }

    subject { stage.send(:compile_rep, rep, phase_stack: phase_stack, is_outdated: is_outdated) }

    let(:is_outdated) { true }
    let(:phase_stack) { stage.send(:build_phase_stack) }

    let(:reps) do
      Nanoc::Int::ItemRepRepo.new.tap do |rs|
        rs << rep
        rs << other_rep

        rs.each do |rep|
          rep.snapshot_defs << Nanoc::Core::SnapshotDef.new(:last, binary: false)
        end
      end
    end

    it 'generates expected output' do
      reps = Nanoc::Int::ItemRepRepo.new
      expect { subject }
        .to change { compiler.compilation_context(reps: reps).compiled_content_store.get_current(rep) }
        .from(nil)
        .to(some_textual_content('3'))
    end

    it 'generates notifications in the proper order' do
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_started, rep, :erb).ordered
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :erb).ordered
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered

      subject
    end

    context 'interrupted compilation' do
      let(:item) { Nanoc::Core::Item.new('other=<%= @items["/other.*"].compiled_content %>', {}, '/hi.md') }

      it 'generates expected output' do
        reps = Nanoc::Int::ItemRepRepo.new
        expect(compiler.compilation_context(reps: reps).compiled_content_store.get_current(rep)).to be_nil

        expect { stage.send(:compile_rep, rep, phase_stack: phase_stack, is_outdated: true) }
          .to raise_error(Nanoc::Int::Errors::UnmetDependency)
        stage.send(:compile_rep, other_rep, phase_stack: phase_stack, is_outdated: true)
        stage.send(:compile_rep, rep, phase_stack: phase_stack, is_outdated: true)

        expect(compiler.compilation_context(reps: reps).compiled_content_store.get_current(rep).string).to eql('other=other content')
      end

      it 'generates notifications in the proper order' do
        # rep 1
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_started, rep, :erb).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:dependency_created, item, other_item).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_suspended, rep, anything, anything).ordered

        # rep 2
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, other_rep).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_started, other_rep, :erb).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_ended, other_rep, :erb).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_ended, other_rep).ordered

        # rep 1 (again)
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :erb).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered

        expect { stage.send(:compile_rep, rep, phase_stack: phase_stack, is_outdated: true) }
          .to raise_error(Nanoc::Int::Errors::UnmetDependency)
        stage.send(:compile_rep, other_rep, phase_stack: phase_stack, is_outdated: true)
        stage.send(:compile_rep, rep, phase_stack: phase_stack, is_outdated: true)
      end
    end
  end
end
