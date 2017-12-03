# frozen_string_literal: true

describe Nanoc::Int::OutdatednessStatus do
  let(:status) { described_class.new }

  describe '#reasons' do
    subject { status.reasons }

    context 'default' do
      it { is_expected.to eql([]) }
    end

    context 'one passed in' do
      let(:reasons) do
        [
          Nanoc::Int::OutdatednessReasons::CodeSnippetsModified,
        ]
      end

      let(:status) { described_class.new(reasons: reasons) }

      it { is_expected.to eql(reasons) }
    end

    context 'two passed in' do
      let(:reasons) do
        [
          Nanoc::Int::OutdatednessReasons::CodeSnippetsModified,
          Nanoc::Int::OutdatednessReasons::ContentModified,
        ]
      end

      let(:status) { described_class.new(reasons: reasons) }

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
        Nanoc::Int::Props.new(attributes: true)
      end

      let(:status) { described_class.new(props: props) }

      it { is_expected.to eql(Set.new([:attributes])) }
    end
  end

  describe '#useful_to_apply' do
    subject { status.useful_to_apply?(rule) }

    let(:status) { described_class.new(props: props) }
    let(:props) { Nanoc::Int::Props.new }
    let(:rule) { Nanoc::Int::OutdatednessRules::RulesModified }

    context 'no props' do
      it { is_expected.to be }
    end

    context 'some props' do
      context 'same props' do
        let(:props) { Nanoc::Int::Props.new(compiled_content: true, path: true) }
        it { is_expected.not_to be }
      end

      context 'different props' do
        let(:props) { Nanoc::Int::Props.new(attributes: true) }
        it { is_expected.to be }
      end
    end

    context 'all props' do
      let(:props) { Nanoc::Int::Props.new(raw_content: true, attributes: true, compiled_content: true, path: true) }
      it { is_expected.not_to be }
    end
  end

  describe '#update' do
    subject { status.update(reason) }

    let(:reason) { Nanoc::Int::OutdatednessReasons::ContentModified }

    context 'no existing reason or props' do
      it 'adds a reason' do
        expect(subject.reasons).to eql([reason])
      end
    end

    context 'existing reason' do
      let(:status) { described_class.new(reasons: [old_reason]) }

      let(:old_reason) { Nanoc::Int::OutdatednessReasons::NotWritten }

      it 'adds a reason' do
        expect(subject.reasons).to eql([old_reason, reason])
      end
    end

    context 'existing props' do
      let(:status) { described_class.new(props: Nanoc::Int::Props.new(attributes: true)) }

      it 'updates props' do
        expect(subject.props.active).to eql(Set.new(%i[raw_content attributes compiled_content]))
      end
    end
  end
end
