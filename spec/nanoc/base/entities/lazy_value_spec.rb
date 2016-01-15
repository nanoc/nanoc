describe Nanoc::Int::LazyValue do
  describe '#initialize' do
    let(:value_arg) { 'Hello world' }

    subject { described_class.new(value_arg) }

    describe 'value arg' do
      context 'object' do
        it 'returns value' do
          expect(subject.value).to equal(value_arg)
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
        end

        it 'does not call the proc immediately' do
          expect(call_count).to eql(0)
        end

        it 'returns proc return value' do
          expect(subject.value).to eq('Hello proc')
        end

        it 'only calls the proc once' do
          subject.value
          subject.value
          expect(call_count).to eql(1)
        end
      end
    end
  end

  describe '#transform' do
    class TransformedLazyValue < described_class
      attr_accessor :transform_count

      def initialize(value)
        super(value)
        @transform_count = 0
      end

      def transform(value)
        @transform_count += 1
        'transformed ' + value
      end
    end

    let(:value_arg) { 'value' }

    subject { TransformedLazyValue.new(value_arg) }

    context 'object' do
      it 'does not call transform immediately' do
        expect(subject.transform_count).to eql(0)
      end

      it 'transforms the value' do
        expect(subject.value).to eq('transformed value')
      end

      it 'only transforms once' do
        subject.value
        subject.value
        expect(subject.transform_count).to eql(1)
      end
    end

    context 'proc' do
      let(:value_arg) { proc { 'value' } }

      it 'does not call transform immediately' do
        expect(subject.transform_count).to eql(0)
      end

      it 'transforms the value' do
        expect(subject.value).to eq('transformed value')
      end

      it 'only transforms once' do
        subject.value
        subject.value
        expect(subject.transform_count).to eql(1)
      end
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
