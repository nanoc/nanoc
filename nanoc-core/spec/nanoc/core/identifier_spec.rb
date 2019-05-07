# frozen_string_literal: true

describe Nanoc::Core::Identifier do
  describe '.from' do
    subject { described_class.from(arg) }

    context 'given an identifier' do
      let(:arg) { described_class.new('/foo.md') }

      it 'returns an identifier' do
        expect(subject).to be_a(described_class)
        expect(subject.to_s).to eq('/foo.md')
        expect(subject).to be_full
      end
    end

    context 'given a string' do
      let(:arg) { '/foo.md' }

      it 'returns an identifier' do
        expect(subject).to be_a(described_class)
        expect(subject.to_s).to eq('/foo.md')
        expect(subject).to be_full
      end
    end

    context 'given something else' do
      let(:klass) do
        Class.new do
          def inspect
            'this is #inspect'
          end
        end
      end

      let(:arg) { klass.new }

      it 'raises' do
        expect { subject }.to raise_error(
          Nanoc::Core::Identifier::NonCoercibleObjectError,
          'this is #inspect cannot be converted into a Nanoc::Core::Identifier',
        )
      end
    end
  end

  describe '#initialize' do
    context 'legacy type' do
      it 'does not convert already clean paths' do
        expect(described_class.new('/foo/bar/', type: :legacy).to_s).to eql('/foo/bar/')
      end

      it 'prepends slash if necessary' do
        expect(described_class.new('foo/bar/', type: :legacy).to_s).to eql('/foo/bar/')
      end

      it 'appends slash if necessary' do
        expect(described_class.new('/foo/bar', type: :legacy).to_s).to eql('/foo/bar/')
      end

      it 'removes double slashes at start' do
        expect(described_class.new('//foo/bar/', type: :legacy).to_s).to eql('/foo/bar/')
      end

      it 'removes double slashes at end' do
        expect(described_class.new('/foo/bar//', type: :legacy).to_s).to eql('/foo/bar/')
      end

      it 'freezes' do
        identifier = described_class.new('/foo/bar/', type: :legacy)
        expect { identifier.to_s << 'bbq' }.to raise_frozen_error
      end
    end

    context 'full type' do
      it 'refuses string not starting with a slash' do
        expect { described_class.new('foo') }
          .to raise_error(
            Nanoc::Core::Identifier::InvalidIdentifierError,
            'Invalid identifier (does not start with a slash): "foo"',
          )
      end

      it 'refuses string ending with a slash' do
        expect { described_class.new('/foo/') }
          .to raise_error(
            Nanoc::Core::Identifier::InvalidFullIdentifierError,
            'Invalid full identifier (ends with a slash): "/foo/"',
          )
      end

      it 'refuses string with only slash' do
        expect { described_class.new('/') }
          .to raise_error(
            Nanoc::Core::Identifier::InvalidFullIdentifierError,
            'Invalid full identifier (ends with a slash): "/"',
          )
      end

      it 'has proper string representation' do
        expect(described_class.new('/foo').to_s).to eql('/foo')
      end

      it 'freezes' do
        identifier = described_class.new('/foo/bar')
        expect { identifier.to_s << 'bbq' }.to raise_frozen_error
      end
    end

    context 'other type' do
      it 'errors' do
        expect { described_class.new('foo', type: :donkey) }
          .to raise_error(
            Nanoc::Core::Identifier::InvalidTypeError,
            'Invalid type for identifier: :donkey (can be :full or :legacy)',
          )
      end
    end

    context 'default type' do
      it 'is full' do
        expect(described_class.new('/foo')).to be_full
      end
    end

    context 'other args specified' do
      it 'errors' do
        expect { described_class.new('?', animal: :donkey) }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_s' do
    it 'returns immutable string' do
      expect { described_class.new('foo/', type: :legacy).to_s << 'lols' }.to raise_frozen_error
      expect { described_class.new('/foo').to_s << 'lols' }.to raise_frozen_error
    end
  end

  describe '#to_str' do
    it 'returns immutable string' do
      expect { described_class.new('/foo/bar').to_str << 'lols' }.to raise_frozen_error
    end
  end

  describe 'Comparable' do
    it 'can be compared' do
      expect(described_class.new('/foo/bar') <= '/qux').to be(true)
    end
  end

  describe '#inspect' do
    subject { identifier.inspect }

    let(:identifier) { described_class.new('/foo/bar') }

    it { is_expected.to eq '<Nanoc::Core::Identifier type=full "/foo/bar">' }
  end

  describe '#== and #eql?' do
    context 'comparing with equal identifier' do
      let(:identifier_a) { described_class.new('//foo/bar/', type: :legacy) }
      let(:identifier_b) { described_class.new('/foo/bar//', type: :legacy) }

      it 'is ==' do
        expect(identifier_a).to eq(identifier_b)
      end

      it 'is eql?' do
        expect(identifier_a).to eql(identifier_b)
      end
    end

    context 'comparing with equal string' do
      let(:identifier_a) { described_class.new('//foo/bar/', type: :legacy) }
      let(:identifier_b) { '/foo/bar/' }

      it 'is ==' do
        expect(identifier_a).to eq(identifier_b.to_s)
      end

      it 'is not eql?' do
        expect(identifier_a).not_to eql(identifier_b.to_s)
      end
    end

    context 'comparing with different identifier' do
      let(:identifier_a) { described_class.new('//foo/bar/', type: :legacy) }
      let(:identifier_b) { described_class.new('/baz/qux//', type: :legacy) }

      it 'is not ==' do
        expect(identifier_a).not_to eq(identifier_b)
      end

      it 'is not eql?' do
        expect(identifier_a).not_to eql(identifier_b)
      end
    end

    context 'comparing with different string' do
      let(:identifier_a) { described_class.new('//foo/bar/', type: :legacy) }
      let(:identifier_b) { '/baz/qux/' }

      it 'is not equal' do
        expect(identifier_a).not_to eq(identifier_b)
      end

      it 'is not eql?' do
        expect(identifier_a).not_to eql(identifier_b)
      end
    end

    context 'comparing with something that is not an identifier' do
      let(:identifier_a) { described_class.new('//foo/bar/', type: :legacy) }
      let(:identifier_b) { :donkey }

      it 'is not equal' do
        expect(identifier_a).not_to eq(identifier_b)
        expect(identifier_a).not_to eql(identifier_b)
      end
    end
  end

  describe '#hash' do
    context 'equal identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/', type: :legacy) }
      let(:identifier_b) { described_class.new('/foo/bar//', type: :legacy) }

      it 'is the same' do
        expect(identifier_a.hash == identifier_b.hash).to be(true)
      end
    end

    context 'different identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/', type: :legacy) }
      let(:identifier_b) { described_class.new('/monkey/', type: :legacy) }

      it 'is different' do
        expect(identifier_a.hash == identifier_b.hash).to be(false)
      end
    end
  end

  describe '#=~' do
    subject { identifier =~ pat }

    let(:identifier) { described_class.new('/foo/bar') }

    context 'given a regex' do
      context 'matching regex' do
        let(:pat) { %r{\A/foo/bar} }

        it { is_expected.to be(0) }
      end

      context 'non-matching regex' do
        let(:pat) { %r{\A/qux/monkey} }

        it { is_expected.to be(nil) }
      end
    end

    context 'given a string' do
      context 'matching string' do
        let(:pat) { '/foo/*' }

        it { is_expected.to be(0) }
      end

      context 'non-matching string' do
        let(:pat) { '/qux/*' }

        it { is_expected.to be(nil) }
      end
    end
  end

  describe '#match?' do
    subject { identifier.match?(pat) }

    let(:identifier) { described_class.new('/foo/bar') }

    context 'given a regex' do
      context 'matching regex' do
        let(:pat) { %r{\A/foo/bar} }

        it { is_expected.to be(true) }
        example { expect { subject }.not_to change(Regexp, :last_match) }
      end

      context 'non-matching regex' do
        let(:pat) { %r{\A/qux/monkey} }

        it { is_expected.to be(false) }
        example { expect { subject }.not_to change(Regexp, :last_match) }
      end
    end

    context 'given a string' do
      context 'matching string' do
        let(:pat) { '/foo/*' }

        it { is_expected.to be(true) }
        example { expect { subject }.not_to change(Regexp, :last_match) }
      end

      context 'non-matching string' do
        let(:pat) { '/qux/*' }

        it { is_expected.to be(false) }
        example { expect { subject }.not_to change(Regexp, :last_match) }
      end
    end
  end

  describe '#<=>' do
    let(:identifier) { described_class.new('/foo/bar') }

    it 'compares by string' do
      expect(identifier <=> '/foo/aarghh').to be(1)
      expect(identifier <=> '/foo/bar').to be(0)
      expect(identifier <=> '/foo/qux').to be(-1)
    end
  end

  describe '#prefix' do
    subject { identifier.prefix(prefix) }

    let(:identifier) { described_class.new('/foo') }

    context 'prefix not ending nor starting with a slash' do
      let(:prefix) { 'asdf' }

      it 'raises an error' do
        expect { subject }.to raise_error(
          Nanoc::Core::Identifier::InvalidPrefixError,
          'Invalid prefix (does not start with a slash): "asdf"',
        )
      end
    end

    context 'prefix ending with a slash' do
      let(:prefix) { 'asdf/' }

      it 'raises an error' do
        expect { subject }.to raise_error(
          Nanoc::Core::Identifier::InvalidPrefixError,
          'Invalid prefix (does not start with a slash): "asdf/"',
        )
      end
    end

    context 'prefix ending and starting with a slash' do
      let(:prefix) { '/asdf/' }

      it 'returns a proper new identifier' do
        expect(subject).to be_a(described_class)
        expect(subject.to_s).to eql('/asdf/foo')
      end
    end

    context 'prefix nstarting with a slash' do
      let(:prefix) { '/asdf' }

      it 'returns a proper new identifier' do
        expect(subject).to be_a(described_class)
        expect(subject.to_s).to eql('/asdf/foo')
      end
    end
  end

  describe '#without_ext' do
    subject { identifier.without_ext }

    context 'legacy type' do
      let(:identifier) { described_class.new('/foo/', type: :legacy) }

      it 'raises an error' do
        expect { subject }.to raise_error(
          Nanoc::Core::Identifier::UnsupportedLegacyOperationError,
          'Cannot use this method on legacy identifiers',
        )
      end
    end

    context 'identifier with no extension' do
      let(:identifier) { described_class.new('/foo') }

      it 'does nothing' do
        expect(subject).to eql('/foo')
      end
    end

    context 'identifier with extension' do
      let(:identifier) { described_class.new('/foo.md') }

      it 'removes the extension' do
        expect(subject).to eql('/foo')
      end
    end
  end

  describe '#ext' do
    subject { identifier.ext }

    context 'legacy type' do
      let(:identifier) { described_class.new('/foo/', type: :legacy) }

      it 'raises an error' do
        expect { subject }.to raise_error(Nanoc::Core::Identifier::UnsupportedLegacyOperationError)
      end
    end

    context 'identifier with no extension' do
      let(:identifier) { described_class.new('/foo') }

      it { is_expected.to be_nil }
    end

    context 'identifier with extension' do
      let(:identifier) { described_class.new('/foo.md') }

      it { is_expected.to eql('md') }
    end
  end

  describe '#without_exts' do
    subject { identifier.without_exts }

    context 'legacy type' do
      let(:identifier) { described_class.new('/foo/', type: :legacy) }

      it 'raises an error' do
        expect { subject }.to raise_error(Nanoc::Core::Identifier::UnsupportedLegacyOperationError)
      end
    end

    context 'identifier with no extension' do
      let(:identifier) { described_class.new('/foo') }

      it 'does nothing' do
        expect(subject).to eql('/foo')
      end
    end

    context 'identifier with one extension' do
      let(:identifier) { described_class.new('/foo.md') }

      it 'removes the extension' do
        expect(subject).to eql('/foo')
      end
    end

    context 'identifier with multiple extensions' do
      let(:identifier) { described_class.new('/foo.html.md') }

      it 'removes the extension' do
        expect(subject).to eql('/foo')
      end
    end
  end

  describe '#exts' do
    subject { identifier.exts }

    context 'legacy type' do
      let(:identifier) { described_class.new('/foo/', type: :legacy) }

      it 'raises an error' do
        expect { subject }.to raise_error(Nanoc::Core::Identifier::UnsupportedLegacyOperationError)
      end
    end

    context 'identifier with no extension' do
      let(:identifier) { described_class.new('/foo') }

      it { is_expected.to be_empty }
    end

    context 'identifier with one extension' do
      let(:identifier) { described_class.new('/foo.md') }

      it { is_expected.to eql(['md']) }
    end

    context 'identifier with multiple extensions' do
      let(:identifier) { described_class.new('/foo.html.md') }

      it { is_expected.to eql(%w[html md]) }
    end
  end

  describe '#legacy?' do
    subject { identifier.legacy? }

    context 'legacy type' do
      let(:identifier) { described_class.new('/foo/', type: :legacy) }

      it { is_expected.to be(true) }
    end

    context 'full type' do
      let(:identifier) { described_class.new('/foo', type: :full) }

      it { is_expected.to be(false) }
    end
  end

  describe '#full?' do
    subject { identifier.full? }

    context 'legacy type' do
      let(:identifier) { described_class.new('/foo/', type: :legacy) }

      it { is_expected.to be(false) }
    end

    context 'full type' do
      let(:identifier) { described_class.new('/foo', type: :full) }

      it { is_expected.to be(true) }
    end
  end

  describe '#components' do
    subject { identifier.components }

    context 'no components' do
      let(:identifier) { described_class.new('/', type: :legacy) }

      it { is_expected.to eql([]) }
    end

    context 'one component' do
      let(:identifier) { described_class.new('/foo.md') }

      it { is_expected.to eql(['foo.md']) }
    end

    context 'two components' do
      let(:identifier) { described_class.new('/foo/bar.md') }

      it { is_expected.to eql(['foo', 'bar.md']) }
    end
  end
end
