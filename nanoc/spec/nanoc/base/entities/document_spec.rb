# frozen_string_literal: true

shared_examples 'a document' do
  describe '#initialize' do
    let(:content_arg) { 'Hello world' }
    let(:attributes_arg) { { 'title' => 'Home' } }
    let(:identifier_arg) { '/home.md' }
    let(:checksum_data_arg) { 'abcdef' }
    let(:content_checksum_data_arg) { 'con-cs' }
    let(:attributes_checksum_data_arg) { 'attr-cs' }

    subject do
      described_class.new(
        content_arg,
        attributes_arg,
        identifier_arg,
        checksum_data: checksum_data_arg,
        content_checksum_data: content_checksum_data_arg,
        attributes_checksum_data: attributes_checksum_data_arg,
      )
    end

    describe 'content arg' do
      context 'string' do
        it 'converts content' do
          expect(subject.content).to be_a(Nanoc::Core::TextualContent)
          expect(subject.content.string).to eql('Hello world')
        end
      end

      context 'content' do
        let(:content_arg) { Nanoc::Core::TextualContent.new('foo') }

        it 'reuses content' do
          expect(subject.content).to equal(content_arg)
        end
      end
    end

    describe 'attributes arg' do
      context 'hash' do
        it 'symbolizes attributes' do
          expect(subject.attributes).to eq(title: 'Home')
        end
      end

      context 'proc' do
        call_count = 0
        let(:attributes_arg) do
          proc do
            call_count += 1
            { 'title' => 'Home' }
          end
        end

        before do
          call_count = 0
        end

        it 'does not call the proc immediately' do
          expect(call_count).to eql(0)
        end

        it 'symbolizes attributes' do
          expect(subject.attributes).to eq(title: 'Home')
        end

        it 'only calls the proc once' do
          subject.attributes
          subject.attributes
          expect(call_count).to eql(1)
        end
      end
    end

    describe 'identifier arg' do
      context 'string' do
        it 'converts identifier' do
          expect(subject.identifier).to be_a(Nanoc::Core::Identifier)
          expect(subject.identifier.to_s).to eql('/home.md')
        end
      end

      context 'identifier' do
        let(:identifier_arg) { Nanoc::Core::Identifier.new('/foo.md') }

        it 'retains identifier' do
          expect(subject.identifier).to equal(identifier_arg)
        end
      end
    end

    describe 'checksum_data arg' do
      it 'reuses checksum_data' do
        expect(subject.checksum_data).to eql(checksum_data_arg)
      end
    end

    describe 'content_checksum_data arg' do
      it 'reuses content_checksum_data' do
        expect(subject.content_checksum_data).to eql(content_checksum_data_arg)
      end
    end

    describe 'attributes_checksum_data arg' do
      it 'reuses attributes_checksum_data' do
        expect(subject.attributes_checksum_data).to eql(attributes_checksum_data_arg)
      end
    end
  end

  describe '#freeze' do
    let(:content_arg) { 'Hallo' }
    let(:attributes_arg) { { foo: { bar: 'asdf' } } }
    let(:document) { described_class.new(content_arg, attributes_arg, '/foo.md') }

    before do
      document.freeze
    end

    it 'refuses changes to content' do
      expect { document.instance_variable_set(:@content, 'hah') }.to raise_frozen_error
      expect { document.content.string << 'hah' }.to raise_frozen_error
    end

    it 'refuses to change attributes' do
      expect { document.instance_variable_set(:@attributes, a: 'Hi') }.to raise_frozen_error
      expect { document.attributes[:title] = 'Bye' }.to raise_frozen_error
      expect { document.attributes[:foo][:bar] = 'fdsa' }.to raise_frozen_error
    end

    it 'refuses to change identifier' do
      expect { document.identifier = '/asdf' }.to raise_frozen_error
      expect { document.identifier.to_s << '/omg' }.to raise_frozen_error
    end

    context 'binary content' do
      let(:content_arg) { Nanoc::Core::BinaryContent.new(File.expand_path('foo.dat')) }

      it 'refuses changes to content' do
        expect { document.instance_variable_set(:@content, 'hah') }.to raise_frozen_error
        expect { document.content.filename << 'hah' }.to raise_frozen_error
      end
    end

    context 'attributes block' do
      let(:attributes_arg) { proc { { foo: { bar: 'asdf' } } } }

      it 'gives access to the attributes' do
        expect(document.attributes).to eql(foo: { bar: 'asdf' })
      end

      it 'refuses to change attributes' do
        expect { document.instance_variable_set(:@attributes, a: 'Hi') }.to raise_frozen_error
        expect { document.attributes[:title] = 'Bye' }.to raise_frozen_error
        expect { document.attributes[:foo][:bar] = 'fdsa' }.to raise_frozen_error
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

  describe '#with_identifier_prefix' do
    let(:document) { described_class.new('kontent', { at: 'ribut' }, '/donkey.md') }

    subject { document.with_identifier_prefix('/animals') }

    it 'does not mutate the original' do
      document.freeze
      subject
    end

    it 'returns a new document with a prefixed identifier' do
      expect(subject.identifier).to eq('/animals/donkey.md')
    end

    it 'does not change other data' do
      expect(subject.content).to be_some_textual_content('kontent')
      expect(subject.attributes).to eq(at: 'ribut')
    end
  end

  describe '#identifier=' do
    let(:document) { described_class.new('stuff', {}, '/foo.md') }

    it 'allows changing to a string that contains a full identifier' do
      expect { document.identifier = '/thing' }.not_to raise_error

      expect(document.identifier).to eq('/thing')
      expect(document.identifier).to be_full
    end

    it 'refuses changing to a string that does not contain a full identifier' do
      expect { document.identifier = '/thing/' }
        .to raise_error(Nanoc::Core::Identifier::InvalidFullIdentifierError)
    end

    it 'allos changing to a full identifier' do
      document.identifier = Nanoc::Core::Identifier.new('/thing')

      expect(document.identifier.to_s).to eq('/thing')
      expect(document.identifier).to be_full
    end

    it 'allos changing to a legacy identifier' do
      document.identifier = Nanoc::Core::Identifier.new('/thing/', type: :legacy)

      expect(document.identifier).to eq('/thing/')
      expect(document.identifier).to be_legacy
    end
  end

  describe '#content=' do
    let(:document) do
      described_class.new(
        content_arg,
        attributes_arg,
        '/foo.md',
        checksum_data: 'ch3cksum_d4t4',
        content_checksum_data: 'c0nt3nt_ch3cksum_d4t4',
        attributes_checksum_data: '4ttr_ch3cksum_d4t4',
      )
    end

    let(:content_arg) { 'Hallo' }
    let(:attributes_arg) { { foo: { bar: 'asdf' } } }

    subject { document.content = Nanoc::Core::TextualContent.new('New!') }

    it 'clears checksum' do
      expect { subject }
        .to change { document.checksum_data }
        .from('ch3cksum_d4t4')
        .to(nil)
    end

    it 'clears content checksum' do
      expect { subject }
        .to change { document.content_checksum_data }
        .from('c0nt3nt_ch3cksum_d4t4')
        .to(nil)
    end

    it 'does not clear attributes checksum data' do
      expect { subject }
        .not_to change { document.attributes_checksum_data }
    end
  end

  describe '#set_attribute' do
    let(:document) do
      described_class.new(
        content_arg,
        attributes_arg,
        '/foo.md',
        checksum_data: 'ch3cksum_d4t4',
        content_checksum_data: 'c0nt3nt_ch3cksum_d4t4',
        attributes_checksum_data: '4ttr_ch3cksum_d4t4',
      )
    end

    let(:content_arg) { 'Hallo' }
    let(:attributes_arg) { { foo: { bar: 'asdf' } } }

    subject { document.set_attribute(:key, 'value') }

    it 'clears checksum' do
      expect { subject }
        .to change { document.checksum_data }
        .from('ch3cksum_d4t4')
        .to(nil)
    end

    it 'clears attributes checksum' do
      expect { subject }
        .to change { document.attributes_checksum_data }
        .from('4ttr_ch3cksum_d4t4')
        .to(nil)
    end

    it 'does not clear content checksum data' do
      expect { subject }
        .not_to change { document.content_checksum_data }
    end
  end
end
