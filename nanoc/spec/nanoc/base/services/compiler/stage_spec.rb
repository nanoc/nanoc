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
          def self.to_s
            'My::Klazz'
          end

          def run
            Timecop.freeze(Time.now + 13.57)
            :i_like_donkeys
          end
        end
      end

      it 'sends timing notification' do
        expect { subject }
          .to send_notification(:stage_ran, 13.57, klass)
      end

      it 'sends stage_started' do
        expect { subject }
          .to send_notification(:stage_started, 'Klazz')
      end

      it 'sends stage_ended' do
        expect { subject }
          .to send_notification(:stage_ended, 'Klazz')
      end

      it 'does not send stage_aborted' do
        expect { subject }
          .not_to send_notification(:stage_aborted, 'Klazz')
      end

      it 'returns what #run returns' do
        expect(subject).to be :i_like_donkeys
      end

      context 'erroring' do
        let(:klass) do
          Class.new(described_class) do
            def self.to_s
              'My::Klazz'
            end

            def run
              raise 'boom'
            end
          end
        end

        it 'does not send timing notification' do
          expect { subject rescue nil }
            .not_to send_notification(:stage_ran, 13.57, klass)
        end

        it 'sends stage_started' do
          expect { subject rescue nil }
            .to send_notification(:stage_started, 'Klazz')
        end

        it 'does not send stage_ended' do
          expect { subject rescue nil }
            .not_to send_notification(:stage_ended, 'Klazz')
        end

        it 'sends stage_aborted' do
          expect { subject rescue nil }
            .to send_notification(:stage_aborted, 'Klazz')
        end
      end
    end
  end
end
