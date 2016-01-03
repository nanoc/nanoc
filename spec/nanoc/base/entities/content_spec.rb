describe Nanoc::Int::Content do
  describe '.create' do
    subject { described_class.create(arg, params) }

    let(:params) { {} }

    context 'nil arg' do
      let(:arg) { nil }

      it 'raises' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'content arg' do
      let(:arg) { Nanoc::Int::TextualContent.new('foo') }

      it { is_expected.to eql(arg) }
    end

    context 'with binary: true param' do
      let(:arg) { '/foo.dat' }
      let(:params) { { binary: true } }

      it 'returns binary content' do
        expect(subject).to be_a(Nanoc::Int::BinaryContent)
        expect(subject.filename).to eql('/foo.dat')
      end
    end

    context 'with binary: false param' do
      context 'with filename param' do
        let(:arg) { 'foo' }
        let(:params) { { binary: false, filename: '/foo.md' } }

        it 'returns textual content' do
          expect(subject).to be_a(Nanoc::Int::TextualContent)
          expect(subject.string).to eql('foo')
          expect(subject.filename).to eql('/foo.md')
        end
      end

      context 'without filename param' do
        let(:arg) { 'foo' }
        let(:params) { { binary: false } }

        it 'returns textual content' do
          expect(subject).to be_a(Nanoc::Int::TextualContent)
          expect(subject.string).to eql('foo')
          expect(subject.filename).to be_nil
        end
      end
    end
  end
end

describe Nanoc::Int::TextualContent do
  describe '#initialize' do
    context 'without filename' do
      let(:content) { described_class.new('foo') }

      it 'sets string and filename' do
        expect(content.string).to eq('foo')
        expect(content.filename).to be_nil
      end
    end

    context 'with absolute filename' do
      let(:content) { described_class.new('foo', filename: '/foo.md') }

      it 'sets string and filename' do
        expect(content.string).to eq('foo')
        expect(content.filename).to eq('/foo.md')
      end
    end

    context 'with relative filename' do
      let(:content) { described_class.new('foo', filename: 'foo.md') }

      it 'errors' do
        expect { content }.to raise_error(ArgumentError)
      end
    end

    context 'with proc' do
      call_count = 0
      let(:content) do
        described_class.new(proc do
          call_count += 1
          'foo'
        end)
      end

      before do
        call_count = 0
      end

      it 'does not call the proc immediately' do
        expect(call_count).to eql(0)
      end

      it 'sets string' do
        expect(content.string).to eq('foo')
      end

      it 'only calls the proc once' do
        content.string
        content.string
        expect(call_count).to eql(1)
      end
    end
  end

  describe '#binary?' do
    subject { content.binary? }
    let(:content) { described_class.new('foo') }
    it { is_expected.to eql(false) }
  end

  describe '#freeze' do
    let(:content) { described_class.new('foo', filename: '/asdf.md') }

    before do
      content.freeze
    end

    it 'prevents changes to string' do
      expect(content.string).to be_frozen
      expect { content.string << 'asdf' }.to raise_frozen_error
    end

    it 'prevents changes to filename' do
      expect(content.filename).to be_frozen
      expect { content.filename << 'asdf' }.to raise_frozen_error
    end

    context 'with proc' do
      let(:content) { described_class.new(proc { 'foo' }) }

      it 'prevents changes to string' do
        expect(content.string).to be_frozen
        expect { content.string << 'asdf' }.to raise_frozen_error
      end
    end
  end
end

describe Nanoc::Int::BinaryContent do
  describe '#initialize' do
    let(:content) { described_class.new('/foo.dat') }

    it 'sets filename' do
      expect(content.filename).to eql('/foo.dat')
    end

    context 'with relative filename' do
      let(:content) { described_class.new('foo.dat') }

      it 'errors' do
        expect { content }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#binary?' do
    subject { content.binary? }
    let(:content) { described_class.new('/foo.dat') }
    it { is_expected.to eql(true) }
  end

  describe '#freeze' do
    let(:content) { described_class.new('/foo.dat') }

    before do
      content.freeze
    end

    it 'prevents changes' do
      expect(content.filename).to be_frozen
      expect { content.filename << 'asdf' }.to raise_frozen_error
    end
  end
end
