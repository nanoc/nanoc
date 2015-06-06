describe Nanoc::LayoutView do
  describe '#== and #eql?' do
    let(:layout) { Nanoc::Int::Layout.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(layout) }

    context 'comparing with layout with same identifier' do
      let(:other) { Nanoc::Int::Layout.new('content', {}, '/asdf/') }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with layout with different identifier' do
      let(:other) { Nanoc::Int::Layout.new('content', {}, '/fdsa/') }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with layout view with same identifier' do
      let(:other) { Nanoc::LayoutView.new(Nanoc::Int::Layout.new('content', {}, '/asdf/')) }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with layout view with different identifier' do
      let(:other) { Nanoc::LayoutView.new(Nanoc::Int::Layout.new('content', {}, '/fdsa/')) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#[]' do
    let(:layout) { Nanoc::Int::Layout.new('stuff', { animal: 'donkey' }, '/foo/') }
    let(:view) { described_class.new(layout) }

    subject { view[key] }

    before do
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:visit_started, layout).ordered
      expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:visit_ended, layout).ordered
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

  describe '#hash' do
    let(:layout) { double(:layout, identifier: '/foo/') }
    let(:view) { described_class.new(layout) }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash }
  end
end
