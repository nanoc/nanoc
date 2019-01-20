# frozen_string_literal: true

describe Nanoc::Int::IdentifiableCollection do
  shared_examples 'a generic identifiable collection' do
    subject(:identifiable_collection) { described_class.new(config, objects) }

    let(:config) { Nanoc::Int::Configuration.new(dir: Dir.getwd) }
    let(:objects) { [] }

    describe '#reject' do
      subject { identifiable_collection.reject { |_| false } }

      it { is_expected.to be_a(described_class) }
    end

    describe '#inspect' do
      subject { identifiable_collection.inspect }

      it { is_expected.to eq("<#{described_class}>") }
    end

    describe '#[]' do
      let(:objects) do
        [
          Nanoc::Core::Item.new('asdf', {}, Nanoc::Core::Identifier.new('/one')),
          Nanoc::Core::Item.new('asdf', {}, Nanoc::Core::Identifier.new('/two')),
        ]
      end

      context 'string pattern style is glob' do
        let(:config) { Nanoc::Int::Configuration.new(dir: Dir.getwd).with_defaults }

        it 'handles glob' do
          expect(identifiable_collection['/on*']).to equal(objects[0])
          expect(identifiable_collection['/*wo']).to equal(objects[1])
        end
      end

      context 'string pattern style is glob' do
        let(:config) { Nanoc::Int::Configuration.new(dir: Dir.getwd) }

        it 'does not handle glob' do
          expect(identifiable_collection['/on*']).to be_nil
          expect(identifiable_collection['/*wo']).to be_nil
        end
      end

      it 'handles identifier' do
        expect(identifiable_collection['/one']).to equal(objects[0])
        expect(identifiable_collection['/two']).to equal(objects[1])
      end

      it 'handles malformed identifier' do
        expect(identifiable_collection['one/']).to be_nil
        expect(identifiable_collection['/one/']).to be_nil
        expect(identifiable_collection['one']).to be_nil
        expect(identifiable_collection['//one']).to be_nil
        expect(identifiable_collection['/one//']).to be_nil
      end

      it 'handles regex' do
        expect(identifiable_collection[/one/]).to equal(objects[0])
        expect(identifiable_collection[/on/]).to equal(objects[0])
        expect(identifiable_collection[/\/o/]).to equal(objects[0])
        expect(identifiable_collection[/e$/]).to equal(objects[0])
      end

      context 'frozen' do
        before { identifiable_collection.freeze }

        example do
          expect(identifiable_collection['/one']).to equal(objects[0])
          expect(identifiable_collection['/fifty']).to be_nil
        end
      end
    end

    describe '#find_all' do
      let(:objects) do
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/about.css')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/about.md')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/style.css')),
        ]
      end

      let(:arg) { raise 'override me' }

      subject { identifiable_collection.find_all(arg) }

      context 'with string' do
        let(:arg) { '/*.css' }

        it 'contains objects' do
          expect(subject.size).to eql(2)
          expect(subject.find { |iv| iv.identifier == '/about.css' }).to eq(objects[0])
          expect(subject.find { |iv| iv.identifier == '/style.css' }).to eq(objects[2])
        end
      end

      context 'with regex' do
        let(:arg) { %r{\.css\z} }

        it 'contains objects' do
          expect(subject.size).to eql(2)
          expect(subject.find { |iv| iv.identifier == '/about.css' }).to eq(objects[0])
          expect(subject.find { |iv| iv.identifier == '/style.css' }).to eq(objects[2])
        end
      end
    end

    describe '#object_with_identifier' do
      let(:objects) do
        [
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/about.css')),
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/about.md')),
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/style.css')),
        ]
      end

      let(:arg) { raise 'override me' }

      subject { identifiable_collection.object_with_identifier(arg) }

      context 'with string' do
        let(:arg) { '/about.css' }
        it { is_expected.to eq(objects[0]) }
      end

      context 'with identifier' do
        let(:arg) { Nanoc::Core::Identifier.new('/about.css') }
        it { is_expected.to eq(objects[0]) }
      end

      context 'with glob string' do
        let(:arg) { '/about.*' }
        it { is_expected.to be_nil }
      end
    end

    describe '#reference' do
      subject { identifiable_collection.reference }
      it { is_expected.to eql(expected_reference) }
    end

    describe 'changing identifiers' do
      let(:objects) do
        [
          Nanoc::Core::Item.new('Foo', {}, '/foo'),
        ]
      end

      subject { objects[0].identifier = '/bar' }

      it 'makes /foo nil' do
        expect { subject }
          .to change { identifiable_collection['/foo'] }
          .from(objects[0])
          .to(nil)
      end

      it 'makes /bar non-nil' do
        expect { subject }
          .to change { identifiable_collection['/bar'] }
          .from(nil)
          .to(objects[0])
      end
    end

    describe '#each' do
      let(:objects) do
        [
          Nanoc::Core::Item.new('Foo', {}, '/foo'),
          Nanoc::Core::Item.new('Bar', {}, '/bar'),
        ]
      end

      it 'loops' do
        res = []
        identifiable_collection.each { |i| res << i.identifier.to_s }
        expect(res).to match_array(['/foo', '/bar'])
      end
    end

    describe '#map' do
      let(:objects) do
        [
          Nanoc::Core::Item.new('Foo', {}, '/foo'),
          Nanoc::Core::Item.new('Bar', {}, '/bar'),
        ]
      end

      it 'loops' do
        res = identifiable_collection.map { |i| i.identifier.to_s }
        expect(res).to match_array(['/foo', '/bar'])
      end
    end
  end

  describe Nanoc::Int::ItemCollection do
    let(:expected_reference) { 'items' }
    it_behaves_like 'a generic identifiable collection'
  end

  describe Nanoc::Int::LayoutCollection do
    let(:expected_reference) { 'layouts' }
    it_behaves_like 'a generic identifiable collection'
  end
end
