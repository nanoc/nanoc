# frozen_string_literal: true

describe Nanoc::Int::Compiler::Stage do
  subject(:stage) { klass.new }

  let(:klass) { described_class }

  before { Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0)) }
  after { Timecop.return }

  describe '#call' do
    subject { stage.call }

    it 'raises error' do
      expect { subject }.to raise_error(NotImplementedError)
    end

    context 'actual implementation' do
      let(:klass) do
        Class.new(described_class) do
          def run
            Timecop.freeze(Time.now + 13.57)
          end
        end
      end

      it 'sends notification' do
        expect { subject }
          .to send_notification(:stage_ran, 13.57, klass)
      end
    end
  end
end
