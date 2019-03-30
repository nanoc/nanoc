# frozen_string_literal: true

describe Nanoc::Core::TextualContent do
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
      let(:content_proc) { -> { 'foo' } }
      let(:content) { described_class.new(content_proc) }

      it 'does not call the proc immediately' do
        expect(content_proc).not_to receive(:call)

        content
      end

      it 'sets string' do
        expect(content_proc).to receive(:call).once.and_return('dataz')

        expect(content.string).to eq('dataz')
      end

      it 'only calls the proc once' do
        expect(content_proc).to receive(:call).once.and_return('dataz')

        expect(content.string).to eq('dataz')
        expect(content.string).to eq('dataz')
      end
    end
  end

  describe '#binary?' do
    subject { content.binary? }
    let(:content) { described_class.new('foo') }
    it { is_expected.to be(false) }
  end

  describe '#freeze' do
    let(:content) { described_class.new(+'foo', filename: '/asdf.md') }

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
      let(:content) { described_class.new(proc { +'foo' }) }

      it 'prevents changes to string' do
        expect(content.string).to be_frozen
        expect { content.string << 'asdf' }.to raise_frozen_error
      end
    end
  end

  describe 'marshalling' do
    let(:content) { described_class.new('foo', filename: '/foo.md') }

    it 'dumps as an array' do
      expect(content.marshal_dump).to eq(['/foo.md', 'foo'])
    end

    it 'restores a dumped object' do
      restored = Marshal.load(Marshal.dump(content))
      expect(restored.string).to eq('foo')
      expect(restored.filename).to eq('/foo.md')
    end
  end
end
