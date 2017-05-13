# frozen_string_literal: true

describe Nanoc::Int::LazyValue do
  describe '#value' do
    let(:value_arg) { 'Hello world'.dup }
    let(:lazy_value) { described_class.new(value_arg) }

    subject { lazy_value.value }

    context 'object' do
      it { is_expected.to equal(value_arg) }
    end

    context 'proc' do
      it 'does not call the proc immediately' do
        expect(value_arg).not_to receive(:call)

        lazy_value
      end

      it 'returns proc return value' do
        expect(value_arg).to receive(:call).once.and_return('Hello proc')

        expect(subject).to eql('Hello proc')
      end

      it 'only calls the proc once' do
        expect(value_arg).to receive(:call).once.and_return('Hello proc')

        expect(subject).to eql('Hello proc')
        expect(subject).to eql('Hello proc')
      end
    end
  end

  describe '#map' do
    let(:value_arg) { -> { 'Hello world' } }
    let(:lazy_value) { described_class.new(value_arg) }

    subject { lazy_value.map(&:upcase) }

    it 'does not call the proc immediately' do
      expect(value_arg).not_to receive(:call)

      subject
    end

    it 'returns proc return value' do
      expect(value_arg).to receive(:call).once.and_return('Hello proc')

      expect(subject.value).to eql('HELLO PROC')
    end

    it 'only calls the proc once' do
      expect(value_arg).to receive(:call).once.and_return('Hello proc')

      expect(subject.value).to eql('HELLO PROC')
      expect(subject.value).to eql('HELLO PROC')
    end
  end

  describe '#freeze' do
    let(:value_arg) { 'Hello world' }

    subject { described_class.new(value_arg) }

    before do
      subject.freeze
    end

    context 'object' do
      it 'returns value' do
        expect(subject.value).to equal(value_arg)
      end

      it 'freezes value' do
        expect(subject.value).to be_frozen
      end
    end

    context 'proc' do
      call_count = 0
      let(:value_arg) do
        proc do
          call_count += 1
          'Hello proc'
        end
      end

      before do
        call_count = 0
        subject.freeze
      end

      it 'does not call the proc immediately' do
        expect(call_count).to eql(0)
      end

      it 'returns proc return value' do
        expect(subject.value).to eq('Hello proc')
      end

      it 'freezes upon access' do
        expect(subject.value).to be_frozen
      end
    end
  end
end
