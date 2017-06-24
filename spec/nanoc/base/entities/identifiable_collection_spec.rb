# frozen_string_literal: true

describe Nanoc::Int::IdentifiableCollection do
  shared_examples 'a generic identifiable collection' do
    subject(:identifiable_collection) { described_class.new(config, objects) }

    let(:config) { Nanoc::Int::Configuration.new }
    let(:objects) { [] }

    describe '#reject' do
      subject { identifiable_collection.reject { |_| false } }

      it { is_expected.to be_a(described_class) }
    end

    describe '#[]' do
      let(:objects) do
        [
          Nanoc::Int::Item.new('asdf', {}, Nanoc::Identifier.new('/one')),
          Nanoc::Int::Item.new('asdf', {}, Nanoc::Identifier.new('/two')),
        ]
      end

      context 'string pattern style is glob' do
        let(:config) { Nanoc::Int::Configuration.new.with_defaults }

        it 'handles glob' do
          expect(identifiable_collection['/on*']).to equal(objects[0])
          expect(identifiable_collection['/*wo']).to equal(objects[1])
        end
      end

      context 'string pattern style is glob' do
        let(:config) { Nanoc::Int::Configuration.new }

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
          double(:identifiable, identifier: Nanoc::Identifier.new('/about.css')),
          double(:identifiable, identifier: Nanoc::Identifier.new('/about.md')),
          double(:identifiable, identifier: Nanoc::Identifier.new('/style.css')),
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
          Nanoc::Int::Item.new('stuff', {}, Nanoc::Identifier.new('/about.css')),
          Nanoc::Int::Item.new('stuff', {}, Nanoc::Identifier.new('/about.md')),
          Nanoc::Int::Item.new('stuff', {}, Nanoc::Identifier.new('/style.css')),
        ]
      end

      let(:arg) { raise 'override me' }

      subject { identifiable_collection.object_with_identifier(arg) }

      context 'with string' do
        let(:arg) { '/about.css' }
        it { is_expected.to eq(objects[0]) }
      end

      context 'with identifier' do
        let(:arg) { Nanoc::Identifier.new('/about.css') }
        it { is_expected.to eq(objects[0]) }
      end

      context 'with glob string' do
        let(:arg) { '/about.*' }
        it { is_expected.to be_nil }
      end
    end
  end

  describe Nanoc::Int::ItemCollection do
    it_behaves_like 'a generic identifiable collection'
  end

  describe Nanoc::Int::LayoutCollection do
    it_behaves_like 'a generic identifiable collection'
  end
end
