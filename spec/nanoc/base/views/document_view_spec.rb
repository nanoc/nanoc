shared_examples 'a document view' do
  let(:view) { described_class.new(document, view_context) }

  let(:view_context) do
    Nanoc::ViewContext.new(
      reps: double(:reps),
      items: double(:items),
      dependency_tracker: dependency_tracker,
    )
  end

  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }

  describe '#== and #eql?' do
    let(:document) { entity_class.new('content', {}, '/asdf/') }

    context 'comparing with document with same identifier' do
      let(:other) { entity_class.new('content', {}, '/asdf/') }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with document with different identifier' do
      let(:other) { entity_class.new('content', {}, '/fdsa/') }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with document view with same identifier' do
      let(:other) { Nanoc::LayoutView.new(entity_class.new('content', {}, '/asdf/'), nil) }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with document view with different identifier' do
      let(:other) { Nanoc::LayoutView.new(entity_class.new('content', {}, '/fdsa/'), nil) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with other object' do
      let(:other) { nil }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#[]' do
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }

    subject { view[key] }

    before do
      expect(dependency_tracker).to receive(:enter).with(document)
      expect(dependency_tracker).to receive(:exit).with(document)
    end

    context 'with existant key' do
      let(:key) { :animal }
      it { is_expected.to eql('donkey') }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }
      it { is_expected.to eql(nil) }
    end
  end

  describe '#attributes' do
    # FIXME: rename :item to :document (and remove duplicate :view)
    let(:item) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }
    let(:view) { described_class.new(item, view_context) }

    subject { view.attributes }

    before do
      expect(dependency_tracker).to receive(:enter).with(item)
      expect(dependency_tracker).to receive(:exit).with(item)
    end

    it 'returns attributes' do
      expect(subject).to eql(animal: 'donkey')
    end
  end

  describe '#fetch' do
    # FIXME: rename :item to :document (and remove duplicate :view)
    let(:item) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }
    let(:view) { described_class.new(item, view_context) }

    before do
      expect(dependency_tracker).to receive(:enter).with(item)
      expect(dependency_tracker).to receive(:exit).with(item)
    end

    context 'with existant key' do
      let(:key) { :animal }

      subject { view.fetch(key) }

      it { should eql?('donkey') }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      context 'with fallback' do
        subject { view.fetch(key, 'nothing sorry') }
        it { should eql?('nothing sorry') }
      end

      context 'with block' do
        subject { view.fetch(key) { 'nothing sorry' } }
        it { should eql?('nothing sorry') }
      end

      context 'with no fallback and no block' do
        subject { view.fetch(key) }

        it 'raises' do
          expect { subject }.to raise_error(KeyError)
        end
      end
    end
  end

  describe '#key?' do
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }

    subject { view.key?(key) }

    before do
      expect(dependency_tracker).to receive(:enter).with(document)
      expect(dependency_tracker).to receive(:exit).with(document)
    end

    context 'with existant key' do
      let(:key) { :animal }
      it { should eql?(true) }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }
      it { should eql?(false) }
    end
  end

  describe '#hash' do
    let(:document) { double(:document, identifier: '/foo/') }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash }
  end
end
