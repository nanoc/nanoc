# frozen_string_literal: true

describe Nanoc::Core::OutdatednessStatus do
  let(:status) { described_class.new }

  describe '#reasons' do
    subject { status.reasons }

    context 'default' do
      it { is_expected.to eql([]) }
    end

    context 'one passed in' do
      let(:reasons) do
        [
          Nanoc::Core::OutdatednessReasons::CodeSnippetsModified,
        ]
      end

      let(:status) { described_class.new(reasons:) }

      it { is_expected.to eql(reasons) }
    end

    context 'two passed in' do
      let(:reasons) do
        [
          Nanoc::Core::OutdatednessReasons::CodeSnippetsModified,
          Nanoc::Core::OutdatednessReasons::ContentModified,
        ]
      end

      let(:status) { described_class.new(reasons:) }

      it { is_expected.to eql(reasons) }
    end
  end

  describe '#props' do
    subject { status.props.active }

    context 'default' do
      it { is_expected.to eql(Set.new) }
    end

    context 'specific one passed in' do
      let(:props) do
        Nanoc::Core::DependencyProps.new(attributes: true)
      end

      let(:status) { described_class.new(props:) }

      it { is_expected.to eql(Set.new([:attributes])) }
    end
  end

  describe '#useful_to_apply' do
    subject { status.useful_to_apply?(rule) }

    let(:status) { described_class.new(props:) }
    let(:props) { Nanoc::Core::DependencyProps.new }

    let(:rule) do
      Class.new(Nanoc::Core::OutdatednessRule) do
        affects_props :compiled_content, :path

        def apply(*args); end
      end
    end

    context 'no props' do
      it { is_expected.to be(true) }
    end

    context 'some props' do
      context 'same props' do
        let(:props) { Nanoc::Core::DependencyProps.new(compiled_content: true, path: true) }

        it { is_expected.to be(false) }
      end

      context 'different props' do
        let(:props) { Nanoc::Core::DependencyProps.new(attributes: true) }

        it { is_expected.to be(true) }
      end
    end

    context 'all props' do
      let(:props) { Nanoc::Core::DependencyProps.new(raw_content: true, attributes: true, compiled_content: true, path: true) }

      it { is_expected.to be(false) }
    end
  end

  describe '#update' do
    subject { status.update(reason) }

    let(:reason) { Nanoc::Core::OutdatednessReasons::ContentModified }

    context 'no existing reason or props' do
      it 'adds a reason' do
        expect(subject.reasons).to eql([reason])
      end
    end

    context 'existing reason' do
      let(:status) { described_class.new(reasons: [old_reason]) }

      let(:old_reason) { Nanoc::Core::OutdatednessReasons::NotWritten }

      it 'adds a reason' do
        expect(subject.reasons).to eql([old_reason, reason])
      end
    end

    context 'existing props' do
      let(:status) { described_class.new(props: Nanoc::Core::DependencyProps.new(attributes: true)) }

      it 'updates props' do
        expect(subject.props.active).to eql(Set.new(%i[raw_content attributes compiled_content]))
      end
    end
  end
end
