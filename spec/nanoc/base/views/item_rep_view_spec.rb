describe Nanoc::ItemRepView do
  let(:view_context) { Nanoc::ViewContext.new(reps: reps, items: items, dependency_tracker: dependency_tracker, compiler: compiler) }

  let(:reps) { double(:reps) }
  let(:items) { double(:items) }
  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }
  let(:compiler) { double(:compiler) }

  describe '#frozen?' do
    let(:item_rep) { Nanoc::Int::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo/') }
    let(:view) { described_class.new(item_rep, view_context) }

    subject { view.frozen? }

    context 'non-frozen item rep' do
      it { is_expected.to be(false) }
    end

    context 'frozen item rep' do
      before { item_rep.freeze }
      it { is_expected.to be(true) }
    end
  end

  describe '#== and #eql?' do
    let(:item_rep) { Nanoc::Int::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo/') }
    let(:view) { described_class.new(item_rep, view_context) }

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :marvin) }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques), view_context) }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques), view_context) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :marvin), view_context) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with something that is not an item rep' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { :donkey }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#hash' do
    let(:item_rep) { Nanoc::Int::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo/') }
    let(:view) { described_class.new(item_rep, view_context) }

    subject { view.hash }

    it { should == described_class.hash ^ Nanoc::Identifier.new('/foo/').hash ^ :jacques.hash }
  end

  describe '#compiled_content' do
    subject { view.compiled_content }

    let(:view) { described_class.new(rep, view_context) }

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.compiled = true
        ir.snapshot_contents = {
          last: Nanoc::Int::TextualContent.new('Hallo'),
        }
      end
    end

    let(:item) do
      Nanoc::Int::Item.new('content', {}, '/asdf.md')
    end

    before do
      expect(dependency_tracker).to receive(:enter).with(item)
      expect(dependency_tracker).to receive(:exit).with(item)
    end

    it { should eq('Hallo') }
  end

  describe '#path' do
    subject { view.path }

    let(:view) { described_class.new(rep, view_context) }

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.paths = {
          last: '/about/',
        }
      end
    end

    let(:item) do
      Nanoc::Int::Item.new('content', {}, '/asdf.md')
    end

    before do
      expect(dependency_tracker).to receive(:enter).with(item)
      expect(dependency_tracker).to receive(:exit).with(item)
    end

    it { should eq('/about/') }
  end

  describe '#raw_path' do
    subject { view.raw_path }

    let(:view) { described_class.new(rep, view_context) }

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.raw_paths = {
          last: 'output/about/index.html',
        }
      end
    end

    let(:item) do
      Nanoc::Int::Item.new('content', {}, '/asdf.md')
    end

    before do
      expect(dependency_tracker).to receive(:enter).with(item)
      expect(dependency_tracker).to receive(:exit).with(item)
    end

    it { should eq('output/about/index.html') }
  end

  describe '#item' do
    let(:item_rep) { Nanoc::Int::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo/') }
    let(:view) { described_class.new(item_rep, view_context) }

    subject { view.item }

    it 'returns an item view' do
      expect(subject).to be_a(Nanoc::ItemWithRepsView)
    end

    it 'returns an item view with the right context' do
      expect(subject._context).to equal(view_context)
    end
  end
end
