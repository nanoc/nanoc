# frozen_string_literal: true

describe Nanoc::Core::CompilationStages::CompileReps do
  Class.new(Nanoc::Core::Filter) do
    identifier :simple_erb_vcn3np2ayqmv6ayqp8su2crbusonmgwh

    def run(content, _params = {})
      context = Nanoc::Core::Context.new(assigns)
      ERB.new(content).result(context.get_binding)
    end
  end

  let(:stage) do
    described_class.new(
      reps:,
      outdatedness_store:,
      dependency_store:,
      action_sequences:,
      compilation_context:,
      compiled_content_cache:,
      focus:,
    )
  end

  let(:focus) { nil }

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider:,
      reps:,
      site:,
      compiled_content_cache:,
      compiled_content_store:,
    )
  end

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  let(:action_sequences) { double(:action_sequences) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }
  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }
  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }

  let(:outdatedness_store) { Nanoc::Core::OutdatednessStore.new(config:) }
  let(:dependency_store) { Nanoc::Core::DependencyStore.new(items, layouts, config) }

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
        Nanoc::Core::ProcessingActions::Filter.new(:simple_erb_vcn3np2ayqmv6ayqp8su2crbusonmgwh, {}),
        Nanoc::Core::ProcessingActions::Snapshot.new([:last], []),
      ]

    Nanoc::Core::ActionSequence.new(actions:)
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
        expect(outdatedness_store.include?(rep)).to be(false)
        expect { subject }.not_to change { outdatedness_store.include?(rep) }
      end
    end

    context 'rep in outdatedness store' do
      before do
        outdatedness_store.add(rep)

        # Needed for consistency
        compiled_content_cache[other_rep] = { last: Nanoc::Core::TextualContent.new('asdf') }
      end

      context 'when focus is not specified' do
        let(:focus) { nil }

        it 'compiles individual reps' do
          expect { subject }.to change { compiled_content_store.get(rep, :last) }
            .from(nil)
            .to(some_textual_content('3'))
        end

        it 'removes the item rep from the outdatedness store' do
          expect { subject }.to change { outdatedness_store.include?(rep) }.from(true).to(false)
        end
      end

      context 'when in focus with one entry' do
        let(:focus) { ['/hi.*'] }

        it 'compiles individual reps' do
          expect { subject }.to change { compiled_content_store.get(rep, :last) }
            .from(nil)
            .to(some_textual_content('3'))
        end

        it 'removes the item rep from the outdatedness store' do
          expect { subject }.to change { outdatedness_store.include?(rep) }.from(true).to(false)
        end
      end

      context 'when in focus with multiple entries' do
        let(:focus) { ['/hi.*', '/unrelated.*'] }

        it 'compiles individual reps' do
          expect { subject }.to change { compiled_content_store.get(rep, :last) }
            .from(nil)
            .to(some_textual_content('3'))
        end

        it 'removes the item rep from the outdatedness store' do
          expect { subject }.to change { outdatedness_store.include?(rep) }.from(true).to(false)
        end
      end

      context 'when not in focus' do
        let(:focus) { ['/other.*'] }

        it 'does not compile individual reps' do
          expect { subject }.not_to change { compiled_content_store.get(rep, :last) }
            .from(nil)
        end

        it 'does not remove the item rep from the outdatedness store' do
          expect { subject }.not_to change { outdatedness_store.include?(rep) }.from(true)
        end
      end

      context 'exception' do
        let(:item) { Nanoc::Core::Item.new('<%= \'invalid_ruby %>', {}, '/hi.md') }

        it 'wraps exception' do
          expect { subject }.to raise_error(Nanoc::Core::Errors::CompilationError)
        end

        it 'contains the right item rep in the wrapped exception' do
          expect { subject }.to raise_error do |err|
            expect(err.item_rep).to eql(rep)
          end
        end

        it 'contains the right wrapped exception' do
          expect { subject }.to raise_error do |err|
            expect(err.unwrap).to be_a(SyntaxError)
            expect(err.unwrap.message).to start_with('(erb):1:')
            expect(err.unwrap.message).to include('unterminated string meets end of file')
          end
        end

        it 'keeps the item rep in the outdatedness store' do
          expect(outdatedness_store.include?(rep)).to be(true)
          expect { subject rescue nil }.not_to change { outdatedness_store.include?(rep) }
        end
      end
    end
  end
end
