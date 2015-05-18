# encoding: utf-8

describe Nanoc::Identifier do
  describe '#initialize' do
    context 'legacy style' do
      it 'does not convert already clean paths' do
        expect(described_class.new('/foo/bar/').to_s).to eql('/foo/bar/')
      end

      it 'prepends slash if necessary' do
        expect(described_class.new('foo/bar/').to_s).to eql('/foo/bar/')
      end

      it 'appends slash if necessary' do
        expect(described_class.new('/foo/bar').to_s).to eql('/foo/bar/')
      end

      it 'removes double slashes at start' do
        expect(described_class.new('//foo/bar/').to_s).to eql('/foo/bar/')
      end

      it 'removes double slashes at end' do
        expect(described_class.new('/foo/bar//').to_s).to eql('/foo/bar/')
      end
    end

    context 'full style' do
      it 'refuses string not starting with a slash' do
        expect { described_class.new('foo', style: :full) }.to raise_error('Invalid identifier (does not start with a slash): "foo"')
      end

      it 'has proper string representation' do
        expect(described_class.new('/foo', style: :full).to_s).to eql('/foo')
      end
    end
  end

  describe '#to_s' do
    it 'returns immutable string' do
      expect { described_class.new('foo/').to_s << 'lols' }.to raise_error
      expect { described_class.new('/foo', style: :full).to_s << 'lols' }.to raise_error
    end
  end

  describe '#to_str' do
    it 'returns immutable string' do
      expect { described_class.new('foo/bar/').to_str << 'lols' }.to raise_error
    end
  end

  describe 'Comparable' do
    it 'can be compared' do
      expect(described_class.new('foo/bar/') <= '/qux/').to eql(true)
    end
  end

  describe '#inspect' do
    let(:identifier) { described_class.new('foo/bar/') }

    subject { identifier.inspect }

    it { should == '<Nanoc::Identifier style=legacy "/foo/bar/">' }
  end

  describe '#== and #eql?' do
    context 'equal identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/') }
      let(:identifier_b) { described_class.new('/foo/bar//') }

      it 'is equal to identifier' do
        expect(identifier_a).to eq(identifier_b)
        expect(identifier_a).to eql(identifier_b)
      end

      it 'is equal to string' do
        expect(identifier_a).to eq(identifier_b.to_s)
        expect(identifier_a).to eql(identifier_b.to_s)
      end
    end

    context 'different identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/') }
      let(:identifier_b) { described_class.new('/baz/qux//') }

      it 'differs from identifier' do
        expect(identifier_a).not_to eq(identifier_b)
        expect(identifier_a).not_to eql(identifier_b)
      end

      it 'differs from string' do
        expect(identifier_a).not_to eq(identifier_b.to_s)
        expect(identifier_a).not_to eql(identifier_b.to_s)
      end
    end
  end

  describe '#hash' do
    context 'equal identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/') }
      let(:identifier_b) { described_class.new('/foo/bar//') }

      it 'is the same' do
        expect(identifier_a.hash == identifier_b.hash).to eql(true)
      end
    end

    context 'different identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/') }
      let(:identifier_b) { described_class.new('/monkey/') }

      it 'is different' do
        expect(identifier_a.hash == identifier_b.hash).to eql(false)
      end
    end
  end

  describe '#=~' do
    let(:identifier) { described_class.new('/foo/bar/') }

    subject { identifier =~ pat }

    context 'given a regex' do
      context 'matching regex' do
        let(:pat) { %r{\A/foo/bar} }
        it { is_expected.to eql(0) }
      end

      context 'non-matching regex' do
        let(:pat) { %r{\A/qux/monkey} }
        it { is_expected.to eql(nil) }
      end
    end

    context 'given a string' do
      context 'matching string' do
        let(:pat) { '/foo/*/' }
        it { is_expected.to eql(0) }
      end

      context 'non-matching string' do
        let(:pat) { '/qux/*/' }
        it { is_expected.to eql(nil) }
      end
    end
  end

  describe '#<=>' do
    let(:identifier) { described_class.new('/foo/bar/') }

    it 'compares by string' do
      expect(identifier <=> '/foo/aarghh/').to eql(1)
      expect(identifier <=> '/foo/bar/').to eql(0)
      expect(identifier <=> '/foo/qux/').to eql(-1)
    end
  end

  describe '#prefix' do
    let(:identifier) { described_class.new('/foo', style: :full) }

    subject { identifier.prefix(prefix) }

    context 'prefix not ending nor starting with a slash' do
      let(:prefix) { 'asdf' }

      it 'raises an error' do
        expect { subject }.to raise_error
      end
    end

    context 'prefix ending with a slash' do
      let(:prefix) { 'asdf/' }

      it 'raises an error' do
        expect { subject }.to raise_error
      end
    end

    context 'prefix ending and starting with a slash' do
      let(:prefix) { '/asdf/' }

      it 'returns a proper new identifier' do
        expect(subject).to be_a(Nanoc::Identifier)
        expect(subject.to_s).to eql('/asdf/foo')
      end
    end

    context 'prefix nstarting with a slash' do
      let(:prefix) { '/asdf' }

      it 'returns a proper new identifier' do
        expect(subject).to be_a(Nanoc::Identifier)
        expect(subject.to_s).to eql('/asdf/foo')
      end
    end
  end

  describe '#with_ext' do
    subject { identifier.with_ext(ext) }

    context 'legacy style' do
      let(:identifier) { described_class.new('/foo/') }
      let(:ext) { 'html' }

      it 'raises an error' do
        expect { subject }.to raise_error
      end
    end

    context 'identifier with no extension' do
      let(:identifier) { described_class.new('/foo', style: :full) }

      context 'extension without dot given' do
        let(:ext) { 'html' }

        it 'adds an extension' do
          expect(subject).to eql('/foo.html')
        end
      end

      context 'extension with dot given' do
        let(:ext) { '.html' }

        it 'adds an extension' do
          expect(subject).to eql('/foo.html')
        end
      end

      context 'empty extension given' do
        let(:ext) { '' }

        it 'removes the extension' do
          expect(subject).to eql('/foo')
        end
      end
    end

    context 'identifier with extension' do
      let(:identifier) { described_class.new('/foo.md', style: :full) }

      context 'extension without dot given' do
        let(:ext) { 'html' }

        it 'adds an extension' do
          expect(subject).to eql('/foo.html')
        end
      end

      context 'extension with dot given' do
        let(:ext) { '.html' }

        it 'adds an extension' do
          expect(subject).to eql('/foo.html')
        end
      end

      context 'empty extension given' do
        let(:ext) { '' }

        it 'removes the extension' do
          expect(subject).to eql('/foo')
        end
      end
    end
  end

  describe '#without_ext' do
    subject { identifier.without_ext }

    context 'legacy style' do
      let(:identifier) { described_class.new('/foo/') }

      it 'raises an error' do
        expect { subject }.to raise_error
      end
    end

    context 'identifier with no extension' do
      let(:identifier) { described_class.new('/foo', style: :full) }

      it 'does nothing' do
        expect(subject).to eql('/foo')
      end
    end

    context 'identifier with extension' do
      let(:identifier) { described_class.new('/foo.md', style: :full) }

      it 'removes the extension' do
        expect(subject).to eql('/foo')
      end
    end
  end
end
