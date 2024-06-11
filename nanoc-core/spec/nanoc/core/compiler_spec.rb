# frozen_string_literal: true

describe Nanoc::Core::Compiler do
  Class.new(Nanoc::Core::Filter) do
    identifier :simple_erb_ob3rqra0yc

    def run(content, _params = {})
      context = Nanoc::Core::Context.new(assigns)
      ERB.new(content).result(context.get_binding)
    end
  end

  let(:compiler) do
    described_class.new(
      site,
      compiled_content_cache:,
      checksum_store:,
      action_sequence_store:,
      action_provider:,
      dependency_store:,
      outdatedness_store:,
      focus: nil,
    )
  end

  let(:checksum_store) { Nanoc::Core::ChecksumStore.new(config:, objects: items) }
  let(:action_sequence_store) { Nanoc::Core::ActionSequenceStore.new(config:) }

  let(:dependency_store) { Nanoc::Core::DependencyStore.new(items, layouts, config) }

  let(:outdatedness_store) { Nanoc::Core::OutdatednessStore.new(config:) }

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  let(:compiled_content_cache) do
    Nanoc::Core::CompiledContentCache.new(config:)
  end

  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Core::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }

  let(:other_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }
  let(:other_item) { Nanoc::Core::Item.new('other content', {}, '/other.md') }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets:,
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
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
        Nanoc::Core::ProcessingActions::Filter.new(:simple_erb_ob3rqra0yc, {}),
        Nanoc::Core::ProcessingActions::Snapshot.new([:last], []),
      ]

    Nanoc::Core::ActionSequence.new(actions:)
  end

  let(:action_sequences) do
    { rep => memory, other_rep => memory }
  end

  before do
    allow(Nanoc::Core::NotificationCenter).to receive(:post)
  end

  describe '#compile_rep' do
    subject { stage.send(:compile_rep, rep, phase_stack:, is_outdated:) }

    let(:stage) { compiler.send(:compile_reps_stage, action_sequences, reps) }

    let(:is_outdated) { true }
    let(:phase_stack) { stage.send(:build_phase_stack) }

    let(:reps) do
      Nanoc::Core::ItemRepRepo.new.tap do |rs|
        rs << rep
        rs << other_rep

        rs.each do |rep|
          rep.snapshot_defs << Nanoc::Core::SnapshotDef.new(:last, binary: false)
        end
      end
    end

    it 'generates expected output' do
      reps = Nanoc::Core::ItemRepRepo.new
      expect { subject }
        .to change { compiler.compilation_context(reps:).compiled_content_store.get_current(rep) }
        .from(nil)
        .to(some_textual_content('3'))
    end

    it 'generates notifications in the proper order' do
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_started, rep, :simple_erb_ob3rqra0yc).ordered
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :simple_erb_ob3rqra0yc).ordered
      expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered

      subject
    end

    context 'interrupted compilation' do
      let(:item) { Nanoc::Core::Item.new('other=<%= @items["/other.*"].compiled_content %>', {}, '/hi.md') }

      it 'generates expected output' do
        reps = Nanoc::Core::ItemRepRepo.new
        expect(compiler.compilation_context(reps:).compiled_content_store.get_current(rep)).to be_nil

        expect { stage.send(:compile_rep, rep, phase_stack:, is_outdated: true) }
          .to raise_error(Nanoc::Core::Errors::UnmetDependency)
        stage.send(:compile_rep, other_rep, phase_stack:, is_outdated: true)
        stage.send(:compile_rep, rep, phase_stack:, is_outdated: true)

        expect(compiler.compilation_context(reps:).compiled_content_store.get_current(rep).string).to eql('other=other content')
      end

      it 'generates notifications in the proper order' do
        # rep 1
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_started, rep, :simple_erb_ob3rqra0yc).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:dependency_created, item, other_item).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_suspended, rep, anything, anything).ordered

        # rep 2
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, other_rep).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_started, other_rep, :simple_erb_ob3rqra0yc).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_ended, other_rep, :simple_erb_ob3rqra0yc).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_ended, other_rep).ordered

        # rep 1 (again)
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_started, rep).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :simple_erb_ob3rqra0yc).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:compilation_ended, rep).ordered

        expect { stage.send(:compile_rep, rep, phase_stack:, is_outdated: true) }
          .to raise_error(Nanoc::Core::Errors::UnmetDependency)
        stage.send(:compile_rep, other_rep, phase_stack:, is_outdated: true)
        stage.send(:compile_rep, rep, phase_stack:, is_outdated: true)
      end
    end
  end
end
