# frozen_string_literal: true

describe Nanoc::Core::IdentifiableCollection do
  shared_examples 'a generic identifiable collection' do
    subject(:identifiable_collection) { described_class.new(config, objects) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd) }
    let(:objects) { [] }

    describe '#reject' do
      subject { identifiable_collection.reject { |_| false } }

      it { is_expected.to be_a(described_class) }
    end

    describe '#inspect' do
      subject { identifiable_collection.inspect }

      it { is_expected.to eq("<#{described_class}>") }
    end

    describe '#object_with_identifier' do
      subject(:object_with_identifier) { identifiable_collection.object_with_identifier(arg) }

      let(:objects) do
        [
          Nanoc::Core::Item.new('Foo', {}, '/foo.md'),
          Nanoc::Core::Item.new('Bar', {}, '/bar.md'),
          Nanoc::Core::Item.new('Quz', {}, '/qux.md'),
        ]
      end

      shared_examples 'object_with_identifier' do
        context 'when given an identifier' do
          context 'when object does not exist' do
            let(:arg) { Nanoc::Core::Identifier.new('/nope.md') }

            it 'returns nil' do
              expect(object_with_identifier).to be_nil
            end
          end

          context 'when object exist' do
            let(:arg) { Nanoc::Core::Identifier.new('/foo.md') }

            it 'returns object' do
              expect(object_with_identifier).to eq(objects[0])
            end
          end
        end

        context 'when given a string' do
          context 'when object does not exist' do
            let(:arg) { '/nope.md' }

            it 'returns nil' do
              expect(object_with_identifier).to be_nil
            end
          end

          context 'when object exist' do
            let(:arg) { '/foo.md' }

            it 'returns object' do
              expect(object_with_identifier).to eq(objects[0])
            end
          end
        end
      end

      context 'when frozen' do
        before { identifiable_collection.freeze }

        include_examples 'object_with_identifier'
      end

      context 'when not frozen' do
        include_examples 'object_with_identifier'
      end
    end

    describe '#object_matching_glob' do
      subject(:object_matching_glob) { identifiable_collection.object_matching_glob(arg) }

      let(:objects) do
        [
          Nanoc::Core::Item.new('Foo', {}, '/foo.md'),
          Nanoc::Core::Item.new('Bar', {}, '/bar.md'),
          Nanoc::Core::Item.new('Quz', {}, '/qux.md'),
        ]
      end

      shared_examples 'object_matching_glob' do
        context 'when object does not exist' do
          let(:arg) { '/nope.*' }

          it 'returns nil' do
            expect(object_matching_glob).to be_nil
          end
        end

        context 'when object exist' do
          let(:arg) { '/foo.*' }

          context 'when globs are enabled' do
            let(:config) { super().merge(string_pattern_type: 'glob') }

            it 'returns object' do
              expect(object_matching_glob).to eq(objects[0])
            end
          end

          context 'when globs are disabled' do
            let(:config) { super().merge(string_pattern_type: 'legacy') }

            it 'returns nil' do
              expect(object_matching_glob).to be_nil
            end
          end
        end
      end

      context 'when frozen' do
        before { identifiable_collection.freeze }

        include_examples 'object_matching_glob'
      end

      context 'when not frozen' do
        include_examples 'object_matching_glob'
      end
    end

    describe '#find_all' do
      subject { identifiable_collection.find_all(arg) }

      let(:objects) do
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/about.css')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/about.md')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/style.css')),
        ]
      end

      let(:arg) { raise 'override me' }

      context 'with string' do
        let(:arg) { '/*.css' }

        it 'contains objects' do
          expect(subject.size).to be(2)
          expect(subject.find { |iv| iv.identifier == '/about.css' }).to eq(objects[0])
          expect(subject.find { |iv| iv.identifier == '/style.css' }).to eq(objects[2])
        end
      end

      context 'with regex' do
        let(:arg) { %r{\.css\z} }

        it 'contains objects' do
          expect(subject.size).to be(2)
          expect(subject.find { |iv| iv.identifier == '/about.css' }).to eq(objects[0])
          expect(subject.find { |iv| iv.identifier == '/style.css' }).to eq(objects[2])
        end
      end
    end

    describe '#freeze' do
      subject { identifiable_collection.freeze }

      let(:objects) do
        [
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/about.css')),
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/about.md')),
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/style.css')),
        ]
      end

      it 'freezes' do
        expect { subject }
          .to change(identifiable_collection, :frozen?)
          .from(false)
          .to(true)
      end
    end

    describe '#object_with_identifier' do
      subject { identifiable_collection.object_with_identifier(arg) }

      let(:objects) do
        [
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/about.css')),
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/about.md')),
          Nanoc::Core::Item.new('stuff', {}, Nanoc::Core::Identifier.new('/style.css')),
        ]
      end

      let(:arg) { raise 'override me' }

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
      subject { objects[0].identifier = '/bar' }

      let(:objects) do
        [
          Nanoc::Core::Item.new('Foo', {}, '/foo'),
        ]
      end

      it 'makes /foo nil' do
        expect { subject }
          .to change { identifiable_collection.object_with_identifier('/foo') }
          .from(objects[0])
          .to(nil)
      end

      it 'makes /bar non-nil' do
        expect { subject }
          .to change { identifiable_collection.object_with_identifier('/bar') }
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
        res = identifiable_collection.map { _1.identifier.to_s }
        expect(res).to contain_exactly('/foo', '/bar')
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
        expect(res).to contain_exactly('/foo', '/bar')
      end
    end
  end

  it 'cannot be instantiated' do
    expect { described_class.new }
      .to raise_error(
        RuntimeError,
        'IdentifiableCollection is abstract and cannot be instantiated',
      )
  end

  describe Nanoc::Core::ItemCollection do
    let(:expected_reference) { 'items' }

    it_behaves_like 'a generic identifiable collection'
  end

  describe Nanoc::Core::LayoutCollection do
    let(:expected_reference) { 'layouts' }

    it_behaves_like 'a generic identifiable collection'
  end
end
