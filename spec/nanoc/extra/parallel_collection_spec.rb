# frozen_string_literal: true

describe Nanoc::Extra::ParallelCollection do
  subject(:col) { described_class.new(wrapped, parallelism: parallelism) }
  let(:wrapped) { [1, 2, 3, 4, 5] }
  let(:parallelism) { 5 }

  describe '#each' do
    subject do
      col.each do |e|
        sleep 0.1
        out << e
      end
    end
    let!(:out) { [] }

    it 'is fast' do
      expect { subject }.to finish_in_under(0.25).seconds
    end

    it 'is correct' do
      expect { subject }.to change { out.sort }.from([]).to([1, 2, 3, 4, 5])
    end

    it 'does not leave threads lingering' do
      expect { subject }.not_to change { Thread.list.size }
    end

    context 'errors' do
      subject do
        col.each do |e|
          if e == 1
            sleep 0.02
            raise 'ugh'
          else
            sleep 0.1
            out << e
          end
        end
      end

      let(:parallelism) { 3 }

      it 'raises' do
        expect { subject }.to raise_error(RuntimeError, 'ugh')
      end

      it 'aborts early' do
        expect { subject rescue nil }.to change { out.sort }.from([]).to([2, 3])
      end
    end

    context 'low parallelism' do
      let(:parallelism) { 1 }

      it 'is not fast' do
        expect { subject }.not_to finish_in_under(0.5).seconds
      end
    end
  end

  describe '#map' do
    subject do
      col.map do |e|
        sleep 0.1
        e * 10
      end
    end

    it 'is fast' do
      expect { subject }.to finish_in_under(0.25).seconds
    end

    it 'does not leave threads lingering' do
      expect { subject }.not_to change { Thread.list.size }
    end

    it 'is correct' do
      expect(subject.sort).to eq([10, 20, 30, 40, 50])
    end

    context 'errors' do
      subject do
        col.each do |e|
          if e == 1
            sleep 0.02
            raise 'ugh'
          else
            sleep 0.1
            e * 10
          end
        end
      end

      let(:parallelism) { 3 }

      it 'raises' do
        expect { subject }.to raise_error(RuntimeError, 'ugh')
      end
    end

    context 'low parallelism' do
      let(:parallelism) { 1 }

      it 'is not fast' do
        expect { subject }.not_to finish_in_under(0.5).seconds
      end
    end
  end
end
