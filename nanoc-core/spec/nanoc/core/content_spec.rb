# frozen_string_literal: true

describe Nanoc::Core::Content do
  describe '.create' do
    subject { described_class.create(arg, **params) }

    let(:params) { {} }

    context 'nil arg' do
      let(:arg) { nil }

      it 'raises' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'content arg' do
      let(:arg) { Nanoc::Core::TextualContent.new('foo') }

      it { is_expected.to eql(arg) }
    end

    context 'with binary: true param' do
      let(:arg) { '/foo.dat' }
      let(:params) { { binary: true } }

      it 'returns binary content' do
        expect(subject).to be_a(Nanoc::Core::BinaryContent)
        expect(subject.filename).to eql('/foo.dat')
      end
    end

    context 'with binary: false param' do
      context 'with filename param' do
        let(:arg) { 'foo' }
        let(:params) { { binary: false, filename: } }

        context 'with relative filename param' do
          let(:filename) { 'foo.md' }

          it 'raises' do
            expect { subject }.to raise_error(
              ArgumentError,
              'Content filename foo.md is not absolute',
            )
          end
        end

        context 'with absolute filename param' do
          let(:filename) { '/foo.md' }

          it 'returns textual content' do
            expect(subject).to be_a(Nanoc::Core::TextualContent)
            expect(subject.string).to eql('foo')
            expect(subject.filename).to eql('/foo.md')
          end
        end
      end

      context 'without filename param' do
        let(:arg) { 'foo' }
        let(:params) { { binary: false } }

        it 'returns textual content' do
          expect(subject).to be_a(Nanoc::Core::TextualContent)
          expect(subject.string).to eql('foo')
          expect(subject.filename).to be_nil
        end
      end
    end
  end

  describe '#binary?' do
    subject { content.binary? }

    let(:content) { described_class.new('/home/denis/stuff.txt') }

    it 'raises' do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end
