# frozen_string_literal: true

describe Nanoc::Int::Compiler::Phases::Resume do
  subject(:phase) do
    described_class.new(
      wrapped: wrapped,
    )
  end

  let(:wrapped_class) do
    Class.new(Nanoc::Int::Compiler::Phases::Abstract) do
      attr_reader :count

      def self.to_s
        'MyPhaseClass'
      end

      def initialize(other_rep)
        super(wrapped: nil)

        @other_rep = other_rep
        @count = 0
      end

      def run(_rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        @count += 1
        Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(@other_rep, :last))

        @count += 1
        Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(@other_rep, :last))

        @count += 1
      end
    end
  end

  let(:wrapped) { wrapped_class.new(other_rep) }

  let(:item) { Nanoc::Core::Item.new('item content', {}, '/donkey.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :latex) }

  let(:other_item) { Nanoc::Core::Item.new('other item content', {}, '/other.md') }
  let(:other_rep) { Nanoc::Core::ItemRep.new(other_item, :latex) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  describe '#call' do
    context 'full run' do
      subject do
        phase.call(rep, is_outdated: true)
      end

      it 'delegates to wrapped' do
        expect { subject }.to change(wrapped, :count).from(0).to(3)
      end

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end

      it 'posts correct notifications' do
        begin
          msgs = []
          Nanoc::Core::NotificationCenter.on(:compilation_interrupted, self) { msgs << :compilation_interrupted }

          subject
          Nanoc::Core::NotificationCenter.sync
          expect(msgs).to eq(%i[compilation_interrupted compilation_interrupted])
        ensure
          Nanoc::Core::NotificationCenter.remove(:compilation_interrupted, self)
        end
      end

      context 'wrapped in Notify' do
        let(:phase) do
          Nanoc::Int::Compiler::Phases::Notify.new(wrapped: super())
        end

        it 'posts correct notifications' do
          begin
            msgs = []
            Nanoc::Core::NotificationCenter.on(:compilation_started, self) { msgs << :compilation_started }
            Nanoc::Core::NotificationCenter.on(:compilation_interrupted, self) { msgs << :compilation_interrupted }
            Nanoc::Core::NotificationCenter.on(:compilation_ended, self) { msgs << :compilation_ended }

            subject
            Nanoc::Core::NotificationCenter.sync
            expect(msgs).to eq(%i[compilation_started compilation_interrupted compilation_interrupted compilation_ended])
          ensure
            Nanoc::Core::NotificationCenter.remove(:compilation_ended, self)
            Nanoc::Core::NotificationCenter.remove(:compilation_interrupted, self)
            Nanoc::Core::NotificationCenter.remove(:compilation_started, self)
          end
        end
      end
    end
  end
end
