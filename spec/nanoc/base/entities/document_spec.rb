shared_examples 'a document' do
  describe '#initialize' do
    let(:content_arg) { 'Hello world' }
    let(:attributes_arg) { { 'title' => 'Home' } }
    let(:identifier_arg) { '/home.md' }

    subject { described_class.new(content_arg, attributes_arg, identifier_arg) }

    describe 'content arg' do
      context 'string' do
        it 'converts content' do
          expect(subject.content).to be_a(Nanoc::Int::TextualContent)
          expect(subject.content.string).to eql('Hello world')
        end
      end

      context 'content' do
        let(:content_arg) { Nanoc::Int::TextualContent.new('foo') }

        it 'reuses content' do
          expect(subject.content).to equal(content_arg)
        end
      end
    end

    describe 'attributes arg' do
      it 'symbolizes attributes' do
        expect(subject.attributes).to eq({ title: 'Home' })
      end
    end

    describe 'identifier arg' do
      context 'string' do
        it 'converts identifier' do
          expect(subject.identifier).to be_a(Nanoc::Identifier)
          expect(subject.identifier.to_s).to eql('/home.md')
        end
      end

      context 'identifier' do
        let(:identifier_arg) { Nanoc::Identifier.new('/foo.md') }

        it 'retains identifier' do
          expect(subject.identifier).to equal(identifier_arg)
        end
      end
    end
  end

  describe '#freeze' do
    let(:content_arg) { 'Hallo' }
    let(:document) { described_class.new(content_arg, { foo: { bar: 'asdf' } }, '/foo.md') }

    before do
      document.freeze
    end

    it 'refuses changes to content' do
      expect { document.instance_variable_set(:@content, 'hah') }.to raise_frozen_error
      expect { document.content.string << 'hah' }.to raise_frozen_error
    end

    it 'refuses to change attributes' do
      expect { document.instance_variable_set(:@attributes, { a: 'Hi' }) }.to raise_frozen_error
      expect { document.attributes[:title] = 'Bye' }.to raise_frozen_error
      expect { document.attributes[:foo][:bar] = 'fdsa' }.to raise_frozen_error
    end

    it 'refuses to change identifier' do
      expect { document.identifier = '/asdf' }.to raise_frozen_error
      expect { document.identifier.to_s << '/omg' }.to raise_frozen_error
    end

    context 'binary content' do
      let(:content_arg) { Nanoc::Int::BinaryContent.new(File.expand_path('foo.dat')) }

      it 'refuses changes to content' do
        expect { document.instance_variable_set(:@content, 'hah') }.to raise_frozen_error
        expect { document.content.filename << 'hah' }.to raise_frozen_error
      end
    end
  end

  describe 'equality' do
    let(:content_arg_a) { 'Hello world' }
    let(:content_arg_b) { 'Bye world' }

    let(:attributes_arg_a) { { 'title' => 'Home' } }
    let(:attributes_arg_b) { { 'title' => 'About' } }

    let(:identifier_arg_a) { '/home.md' }
    let(:identifier_arg_b) { '/home.md' }

    let(:document_a) { described_class.new(content_arg_a, attributes_arg_a, identifier_arg_a) }
    let(:document_b) { described_class.new(content_arg_b, attributes_arg_b, identifier_arg_b) }

    subject { document_a == document_b }

    context 'same identifier' do
      let(:identifier_arg_a) { '/home.md' }
      let(:identifier_arg_b) { '/home.md' }

      it { is_expected.to eql(true) }

      it 'has same hashes' do
        expect(document_a.hash).to eql(document_b.hash)
      end
    end

    context 'different identifier' do
      let(:identifier_arg_a) { '/home.md' }
      let(:identifier_arg_b) { '/about.md' }

      it { is_expected.to eql(false) }

      it 'has different hashes' do
        expect(document_a.hash).not_to eql(document_b.hash)
      end
    end

    context 'comparing with non-document' do
      let(:document_b) { nil }

      it { is_expected.to eql(false) }

      it 'has different hashes' do
        expect(document_a.hash).not_to eql(document_b.hash)
      end
    end
  end
end
