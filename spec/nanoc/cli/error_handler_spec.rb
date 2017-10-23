# frozen_string_literal: true

describe Nanoc::CLI::ErrorHandler do
  subject(:error_handler) { described_class.new }

  describe '#forwards_stack_trace?' do
    subject { error_handler.forwards_stack_trace? }

    context 'feature enabled' do
      around do |ex|
        Nanoc::Feature.enable(Nanoc::Feature::SENSIBLE_STACK_TRACES) do
          ex.run
        end
      end

      context 'Ruby 2.4' do
        it { is_expected.to be(true) }
      end

      context 'Ruby 2.5' do
        it { is_expected.to be(true) }
      end
    end

    context 'feature not enabled' do
      context 'Ruby 2.4' do
        before do
          expect(error_handler).to receive(:ruby_version).and_return('2.4.2')
        end

        it { is_expected.to be(false) }
      end

      context 'Ruby 2.5' do
        before do
          expect(error_handler).to receive(:ruby_version).and_return('2.5.0')
        end

        it { is_expected.to be(true) }
      end
    end
  end
end
