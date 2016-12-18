describe Nanoc::Int::Props do
  let(:props) { described_class.new }

  let(:props_all) do
    described_class.new(raw_content: true, attributes: true, compiled_content: true, path: true)
  end

  describe '#inspect' do
    subject { props.inspect }

    context 'nothing active' do
      it { is_expected.to eql('Props(____)') }
    end

    context 'attributes active' do
      let(:props) { described_class.new(attributes: true) }
      it { is_expected.to eql('Props(_a__)') }
    end

    context 'attributes and compiled_content active' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }
      it { is_expected.to eql('Props(_ac_)') }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }
      it { is_expected.to eql('Props(__c_)') }
    end
  end

  describe '#raw_content?' do
    # …
  end

  describe '#attributes?' do
    subject { props.attributes? }

    context 'nothing active' do
      it { is_expected.not_to be }
    end

    context 'attributes active' do
      let(:props) { described_class.new(attributes: true) }
      it { is_expected.to be }
    end

    context 'attributes and compiled_content active' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }
      it { is_expected.to be }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }
      it { is_expected.not_to be }
    end

    context 'all active' do
      let(:props) { described_class.new(raw_content: true, attributes: true, compiled_content: true, path: true) }
      it { is_expected.to be }
    end
  end

  describe '#compiled_content?' do
    # …
  end

  describe '#path?' do
    # …
  end

  describe '#merge' do
    subject { props.merge(other_props).active }

    context 'nothing + nothing' do
      let(:props) { described_class.new }
      let(:other_props) { described_class.new }

      it { is_expected.to eql(Set.new) }
    end

    context 'nothing + some' do
      let(:props) { described_class.new }
      let(:other_props) { described_class.new(raw_content: true) }

      it { is_expected.to eql(Set.new([:raw_content])) }
    end

    context 'nothing + all' do
      let(:props) { described_class.new }
      let(:other_props) { props_all }

      it { is_expected.to eql(Set.new([:raw_content, :attributes, :compiled_content, :path])) }
    end

    context 'some + nothing' do
      let(:props) { described_class.new(compiled_content: true) }
      let(:other_props) { described_class.new }

      it { is_expected.to eql(Set.new([:compiled_content])) }
    end

    context 'some + others' do
      let(:props) { described_class.new(compiled_content: true) }
      let(:other_props) { described_class.new(raw_content: true) }

      it { is_expected.to eql(Set.new([:raw_content, :compiled_content])) }
    end

    context 'some + all' do
      let(:props) { described_class.new(compiled_content: true) }
      let(:other_props) { props_all }

      it { is_expected.to eql(Set.new([:raw_content, :attributes, :compiled_content, :path])) }
    end

    context 'all + nothing' do
      let(:props) { props_all }
      let(:other_props) { described_class.new }

      it { is_expected.to eql(Set.new([:raw_content, :attributes, :compiled_content, :path])) }
    end

    context 'some + all' do
      let(:props) { props_all }
      let(:other_props) { described_class.new(compiled_content: true) }

      it { is_expected.to eql(Set.new([:raw_content, :attributes, :compiled_content, :path])) }
    end

    context 'all + all' do
      let(:props) { props_all }
      let(:other_props) { props_all }

      it { is_expected.to eql(Set.new([:raw_content, :attributes, :compiled_content, :path])) }
    end
  end

  describe '#active' do
    subject { props.active }

    context 'nothing active' do
      let(:props) { described_class.new }
      it { is_expected.to eql(Set.new) }
    end

    context 'raw_content active' do
      let(:props) { described_class.new(raw_content: true) }
      it { is_expected.to eql(Set.new([:raw_content])) }
    end

    context 'attributes active' do
      let(:props) { described_class.new(attributes: true) }
      it { is_expected.to eql(Set.new([:attributes])) }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }
      it { is_expected.to eql(Set.new([:compiled_content])) }
    end

    context 'path active' do
      let(:props) { described_class.new(path: true) }
      it { is_expected.to eql(Set.new([:path])) }
    end

    context 'attributes and compiled_content active' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }
      it { is_expected.to eql(Set.new([:attributes, :compiled_content])) }
    end

    context 'all active' do
      let(:props) { described_class.new(raw_content: true, attributes: true, compiled_content: true, path: true) }
      it { is_expected.to eql(Set.new([:raw_content, :attributes, :compiled_content, :path])) }
    end
  end

  describe '#to_h' do
    subject { props.to_h }

    context 'nothing' do
      let(:props) { described_class.new }
      it { is_expected.to eql(raw_content: false, attributes: false, compiled_content: false, path: false) }
    end

    context 'some' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }
      it { is_expected.to eql(raw_content: false, attributes: true, compiled_content: true, path: false) }
    end

    context 'all' do
      let(:props) { props_all }
      it { is_expected.to eql(raw_content: true, attributes: true, compiled_content: true, path: true) }
    end
  end
end
