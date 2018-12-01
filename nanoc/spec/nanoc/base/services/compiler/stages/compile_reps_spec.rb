# frozen_string_literal: true

describe Nanoc::Int::Compiler::Stages::CompileReps::State do
  let(:state) { described_class.new(outdated_reps) }

  let(:outdated_reps) { known_reps }

  let(:known_reps) { [rep, other_rep_a, other_rep_b] }

  let(:item) { Nanoc::Core::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

  let(:other_item_a) { Nanoc::Core::Item.new('other content', {}, '/othera.md') }
  let(:other_rep_a) { Nanoc::Core::ItemRep.new(other_item_a, :default) }

  let(:other_item_b) { Nanoc::Core::Item.new('other content', {}, '/otherb.md') }
  let(:other_rep_b) { Nanoc::Core::ItemRep.new(other_item_b, :default) }

  describe '#take' do
    subject { state.take }

    context 'some pending reps' do
      it 'returns a random one' do
        expect(known_reps).to include(subject)
      end

      it 'does not change state' do
        expect { subject }
          .not_to change(state, :pending_reps)
      end
    end

    context 'no pending reps' do
      let(:outdated_reps) { [] }

      it 'returns nil' do
        expect(subject).to be_nil
      end

      it 'does not change state' do
        expect { subject }
          .not_to change(state, :pending_reps)
      end
    end
  end

  describe '#mark_as_live' do
    subject { state.mark_as_live(rep) }

    it 'changes pending_reps' do
      expect { subject }
        .to change(state, :pending_reps)
        .from(Set.new(known_reps))
        .to(Set.new(known_reps) - [rep])
    end

    it 'changes live_reps' do
      expect { subject }
        .to change(state, :live_reps)
        .from(Set.new)
        .to(Set.new([rep]))
    end

    it 'does not change completed_reps' do
      expect { subject }
        .not_to change(state, :completed_reps)
        .from(Set.new)
    end
  end

  describe '#mark_as_live' do
    subject do
      state.mark_as_live(rep)
      state.mark_as_completed(rep)
    end

    it 'changes pending_reps' do
      expect { subject }
        .to change(state, :pending_reps)
        .from(Set.new(known_reps))
        .to(Set.new(known_reps) - [rep])
    end

    it 'does not change live_reps' do
      expect { subject }
        .not_to change(state, :live_reps)
        .from(Set.new)
    end

    it 'changes completed_reps' do
      expect { subject }
        .to change(state, :completed_reps)
        .from(Set.new)
        .to(Set.new([rep]))
    end
  end

  describe '#outdated?' do
    subject { state.outdated?(rep) }

    context 'outdated' do
      it { is_expected.to be(true) }
    end

    context 'not outdated' do
      before do
        state.mark_as_live(rep)
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#done?' do
    subject { state.done? }

    context 'some pending reps' do
      # `rep` is the pending rep in this test case

      context 'some live reps' do
        before do
          state.mark_as_live(other_rep_a)
          state.mark_as_live(other_rep_b)
        end

        context 'some completed reps' do
          before do
            state.mark_as_completed(other_rep_b)
          end

          it { is_expected.to be(false) }
        end

        context 'no completed reps' do
          it { is_expected.to be(false) }
        end
      end

      context 'no live reps' do
        context 'some completed reps' do
          before do
            state.mark_as_live(other_rep_b)
            state.mark_as_completed(other_rep_b)
          end

          it { is_expected.to be(false) }
        end

        context 'no completed reps' do
          it { is_expected.to be(false) }
        end
      end
    end

    context 'no pending reps' do
      before do
        state.mark_as_live(rep)
        state.mark_as_live(other_rep_a)
        state.mark_as_live(other_rep_b)
      end

      context 'some live reps' do
        context 'some completed reps' do
          before do
            state.mark_as_completed(other_rep_b)
          end

          it { is_expected.to be(false) }
        end

        context 'no completed reps' do
          it { is_expected.to be(false) }
        end
      end

      context 'no live reps' do
        before do
          state.mark_as_completed(rep)
          state.mark_as_completed(other_rep_a)
          state.mark_as_completed(other_rep_b)
        end

        it { is_expected.to be(true) }
      end
    end
  end

  describe '#in_progress_or_done?' do
    subject { state.in_progress_or_done?(rep) }

    context 'pending' do
      it { is_expected.to be(false) }
    end

    context 'in progress' do
      before do
        state.mark_as_live(rep)
      end

      it { is_expected.to be(true) }
    end

    context 'done' do
      before do
        state.mark_as_live(rep)
        state.mark_as_completed(rep)
      end

      it { is_expected.to be(true) }
    end
  end
end

describe Nanoc::Int::Compiler::Stages::CompileReps::ThreadPool do
  let(:thread_pool) do
    described_class.new(
      queue: queue,
      state: state,
      phase_stack: phase_stack,
      parallelism: parallelism,
    )
  end

  let(:queue) { Queue.new }
  let(:state) { Nanoc::Int::Compiler::Stages::CompileReps::State.new(outdated_reps) }
  let(:parallelism) { 1 } # makes it easy/reliable to test

  let(:phase_stack_with_waiter_class) do
    Class.new do
      def initialize(waiter:)
        @waiter = waiter
      end

      def call(_rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        @waiter.value
      end
    end
  end

  let(:phase_stack_with_waiter_and_error_class) do
    Class.new do
      def initialize(waiter:)
        @waiter = waiter
      end

      def call(_rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        @waiter.value
        raise 'boom'
      end
    end
  end

  let(:phase_stack_with_dependency_handling_class) do
    Class.new do
      def initialize(dependencies_map:, unblocking_map:)
        # Map of rep A -> rep B, where rep A has a hard dependency on rep B
        @dependencies_map = dependencies_map

        # Map of rep -> future
        @unblocking_map = unblocking_map
      end

      def call(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        dependent_rep = @dependencies_map[rep]

        if dependent_rep
          Nanoc::Core::NotificationCenter.post(
            :compilation_interrupted, rep, dependent_rep, :last
          )

          dependent_promise = @unblocking_map[dependent_rep]
          dependent_promise&.value
        end

        promise = @unblocking_map[rep]
        promise&.fulfill(true)
      end
    end
  end

  let(:phase_stack) do
    phase_stack_with_waiter_class.new(waiter: waiter)
  end

  let(:outdated_reps) { known_reps }

  let(:known_reps) { [rep, other_rep_a, other_rep_b] }

  let(:item) { Nanoc::Core::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

  let(:other_item_a) { Nanoc::Core::Item.new('other content', {}, '/othera.md') }
  let(:other_rep_a) { Nanoc::Core::ItemRep.new(other_item_a, :default) }

  let(:other_item_b) { Nanoc::Core::Item.new('other content', {}, '/otherb.md') }
  let(:other_rep_b) { Nanoc::Core::ItemRep.new(other_item_b, :default) }

  let(:waiter) { Concurrent::Promises.resolvable_future }

  after do
    thread_pool.shutdown
    thread_pool.wait_for_termination
  end

  it 'can schedule on the main pool' do
    expect(queue).to be_empty
    expect(thread_pool.main_free?).to be

    thread_pool.schedule_main(rep)

    expect(queue).to be_empty
    expect(thread_pool.main_free?).not_to be

    waiter.fulfill(true)

    expect(queue.pop).to eq([:done, rep])
    expect(queue).to be_empty
    expect(thread_pool.main_free?).to be
  end

  it 'can schedule on the extra pool' do
    expect(queue).to be_empty
    expect(thread_pool.main_free?).to be

    thread_pool.schedule_extra(rep, is_outdated: false)

    expect(queue).to be_empty
    expect(thread_pool.main_free?).to be # main is not affected

    waiter.fulfill(true)

    expect(queue.pop).to eq([:done, rep])
    expect(queue).to be_empty
    expect(thread_pool.main_free?).to be
  end

  context 'error' do
    let(:phase_stack) { phase_stack_with_waiter_and_error_class.new(waiter: waiter) }

    it 'recovers properly' do
      expect(queue).to be_empty
      expect(thread_pool.main_free?).to be

      thread_pool.schedule_main(rep)

      expect(queue).to be_empty
      expect(thread_pool.main_free?).not_to be

      waiter.fulfill(true)

      expect(queue.pop.take(2)).to eq([:error, rep])
      expect(queue.pop).to eq([:done, rep])
      expect(queue).to be_empty
      expect(thread_pool.main_free?).to be
    end
  end

  context 'dependencies' do
    let(:phase_stack) do
      phase_stack_with_dependency_handling_class.new(
        dependencies_map: {
          rep => other_rep_a,
          other_rep_a => other_rep_b,
        },
        unblocking_map: {
          other_rep_a => unblock_a,
          other_rep_b => unblock_b,
        },
      )
    end

    let(:unblock_a) { Concurrent::Promises.resolvable_future }
    let(:unblock_b) { Concurrent::Promises.resolvable_future }

    it 'can handle dependencies' do
      expect(queue).to be_empty

      # For testing purposes only: manually wait (to run assertions), and then
      # resume compilation.
      wait_for_other_rep_b = Concurrent::Promises.resolvable_future

      nc = Nanoc::Core::NotificationCenter
      nc.on(:compilation_interrupted, self) do |_rep, target_rep, _target_snapshot_name|
        if target_rep == other_rep_b
          # Wait for assertions to complete and then go ahead with compilation
          wait_for_other_rep_b.value
        end

        thread_pool.schedule_extra(target_rep, is_outdated: true)
      end

      expect(thread_pool.main_free?).to be(true)
      thread_pool.schedule_main(rep)
      expect(thread_pool.main_free?).to be(false)

      # Start compiling
      wait_for_other_rep_b.fulfill(true)

      # The order here is important — that is now the dependencies work.
      expect(queue.pop).to eq([:done, other_rep_b])
      expect(queue.pop).to eq([:done, other_rep_a])
      expect(queue.pop).to eq([:done, rep])
      expect(queue).to be_empty
    end
  end
end

describe Nanoc::Int::Compiler::Stages::CompileReps do
  let(:stage) do
    described_class.new(
      reps: reps,
      outdatedness_store: outdatedness_store,
      dependency_store: dependency_store,
      action_sequences: action_sequences,
      compilation_context: compilation_context,
      compiled_content_cache: compiled_content_cache,
    )
  end

  let(:compilation_context) do
    Nanoc::Int::CompilationContext.new(
      action_provider: action_provider,
      reps: reps,
      site: site,
      compiled_content_cache: compiled_content_cache,
      compiled_content_store: compiled_content_store,
    )
  end

  let(:action_provider) { double(:action_provider) }
  let(:action_sequences) { double(:action_sequences) }
  let(:reps) { Nanoc::Int::ItemRepRepo.new }
  let(:compiled_content_cache) { Nanoc::Int::CompiledContentCache.new(config: config) }
  let(:compiled_content_store) { Nanoc::Int::CompiledContentStore.new }

  let(:outdatedness_store) { Nanoc::Int::OutdatednessStore.new(config: config) }
  let(:dependency_store) { Nanoc::Int::DependencyStore.new(items, layouts, config) }

  let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Core::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }

  let(:other_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }
  let(:other_item) { Nanoc::Core::Item.new('other content', {}, '/other.md') }

  let(:site) do
    Nanoc::Core::Site.new(
      config: config,
      code_snippets: code_snippets,
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:code_snippets) { [] }

  let(:layouts) do
    Nanoc::Core::LayoutCollection.new(config)
  end

  let(:items) do
    Nanoc::Core::ItemCollection.new(
      config,
      [item, other_item],
    )
  end

  let(:memory) do
    actions =
      [
        Nanoc::Core::ProcessingActions::Filter.new(:erb, {}),
        Nanoc::Core::ProcessingActions::Snapshot.new([:last], []),
      ]

    Nanoc::Core::ActionSequence.new(nil, actions: actions)
  end

  before do
    reps << rep
    reps << other_rep

    reps.each do |rep|
      rep.snapshot_defs << Nanoc::Core::SnapshotDef.new(:last, binary: false)
    end

    allow(action_sequences).to receive(:[]).with(rep).and_return(memory)
    allow(action_sequences).to receive(:[]).with(other_rep).and_return(memory)
  end

  describe '#compile_reps' do
    subject { stage.run }

    let(:snapshot_defs_for_rep) do
      [Nanoc::Core::SnapshotDef.new(:last, binary: false)]
    end

    let(:snapshot_defs_for_other_rep) do
      [Nanoc::Core::SnapshotDef.new(:last, binary: false)]
    end

    context 'rep not in outdatedness store' do
      before do
        # Needed for consistency
        compiled_content_cache[rep] = { last: Nanoc::Core::TextualContent.new('asdf') }
        compiled_content_cache[other_rep] = { last: Nanoc::Core::TextualContent.new('asdf') }
      end

      it 'keeps the item rep out of the outdatedness store' do
        expect(outdatedness_store.include?(rep)).not_to be
        expect { subject }.not_to change { outdatedness_store.include?(rep) }
      end
    end

    context 'rep in outdatedness store' do
      before { outdatedness_store.add(rep) }

      before do
        # Needed for consistency
        compiled_content_cache[other_rep] = { last: Nanoc::Core::TextualContent.new('asdf') }
      end

      it 'compiles individual reps' do
        expect { subject }.to change { compiled_content_store.get(rep, :last) }
          .from(nil)
          .to(some_textual_content('3'))
      end

      it 'removes the item rep from the outdatedness store' do
        expect { subject }.to change { outdatedness_store.include?(rep) }.from(true).to(false)
      end

      context 'exception' do
        let(:item) { Nanoc::Core::Item.new('<%= \'invalid_ruby %>', {}, '/hi.md') }

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
            expect(err.unwrap).to be_a(SyntaxError)
            expect(err.unwrap.message).to start_with('item /hi.md (rep default):1: unterminated string meets end of file')
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
