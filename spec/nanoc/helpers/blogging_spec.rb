describe Nanoc::Helpers::Blogging do
  let(:mod) do
    Class.new(Nanoc::Int::Context) do
      include Nanoc::Helpers::Blogging
    end.new(assigns)
  end

  let(:assigns) do
    { items: [] }
  end

  let(:view_context) { Nanoc::ViewContext.new(reps: reps, items: []) }

  let(:reps) do
    Nanoc::Int::ItemRepRepo.new
  end

  describe '#articles' do
    subject { mod.articles }

    let(:item_a) do
      Nanoc::Int::Item.new(
        'blah',
        { kind: 'item' },
        '/0/',
      )
    end

    let(:item_b) do
      Nanoc::Int::Item.new(
        'blah blah',
        { kind: 'article' },
        '/1/',
      )
    end

    let(:item_c) do
      Nanoc::Int::Item.new(
        'blah blah blah',
        { kind: 'article' },
        '/2/',
      )
    end

    let(:assigns) do
      items = Nanoc::Int::IdentifiableCollection.new({})
      items << item_a
      items << item_b
      items << item_c

      { items: Nanoc::ItemCollectionView.new(items, view_context) }
    end

    it 'returns the two articles' do
      expect(subject.size).to eql(2)
      expect(subject.any? { |a| a.unwrap.equal?(item_a) }).to eql(false)
      expect(subject.any? { |a| a.unwrap.equal?(item_b) }).to eql(true)
      expect(subject.any? { |a| a.unwrap.equal?(item_c) }).to eql(true)
    end
  end

  describe '#sorted_articles' do
    subject { mod.sorted_articles }

    let(:item_a) do
      Nanoc::Int::Item.new(
        'blah',
        { kind: 'item' },
        '/0/',
      )
    end

    let(:item_b) do
      Nanoc::Int::Item.new(
        'blah blah',
        { kind: 'article', created_at: (Date.today - 1).to_s },
        '/1/',
      )
    end

    let(:item_c) do
      Nanoc::Int::Item.new(
        'blah blah blah',
        { kind: 'article', created_at: (Time.now - 500).to_s },
        '/2/',
      )
    end

    let(:assigns) do
      items = Nanoc::Int::IdentifiableCollection.new({})
      items << item_a
      items << item_b
      items << item_c

      { items: Nanoc::ItemCollectionView.new(items, view_context) }
    end

    it 'returns the two articles' do
      expect(subject.size).to eql(2)
      expect(subject[0].unwrap).to equal(item_c)
      expect(subject[1].unwrap).to equal(item_b)
    end
  end

  describe '#url_for' do
    subject { mod.url_for(item_view) }

    let(:item) do
      Nanoc::Int::Item.new('Stuff', item_attributes, '/stuff/')
    end

    let(:item_view) do
      Nanoc::ItemView.new(item, view_context)
    end

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |rep|
        rep.paths[:last] = '/rep/path/stuff.html'
      end
    end

    let(:item_attributes) do
      {}
    end

    let(:assigns) do
      {
        config: { base_url: base_url },
      }
    end

    before do
      reps << rep
    end

    context 'without base_url' do
      let(:base_url) { nil }

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Error)
      end
    end

    context 'with base_url' do
      let(:base_url) { 'http://url.base' }

      context 'with custom_url_in_feed' do
        let(:item_attributes) do
          { custom_url_in_feed: 'http://example.com/stuff.html' }
        end

        it 'returns custom URL' do
          expect(subject).to eql('http://example.com/stuff.html')
        end
      end

      context 'without custom_url_in_feed' do
        context 'with custom_path_in_feed' do
          let(:item_attributes) do
            { custom_path_in_feed: '/stuff.html' }
          end

          it 'returns base URL + custom path' do
            expect(subject).to eql('http://url.base/stuff.html')
          end
        end

        context 'without custom_path_in_feed' do
          it 'returns base URL + path' do
            expect(subject).to eql('http://url.base/rep/path/stuff.html')
          end
        end
      end
    end
  end

  describe '#feed_url' do
    subject { mod.feed_url }

    let(:item) do
      Nanoc::Int::Item.new('Feed', item_attributes, '/feed/')
    end

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |rep|
        rep.paths[:last] = '/feed.xml'
      end
    end

    let(:item_view) do
      Nanoc::ItemView.new(item, view_context)
    end

    let(:item_attributes) do
      {}
    end

    let(:assigns) do
      {
        config: { base_url: base_url },
        item: item_view,
      }
    end

    before do
      reps << rep
    end

    context 'without base_url' do
      let(:base_url) { nil }

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Error)
      end
    end

    context 'with base_url' do
      let(:base_url) { 'http://url.base' }

      context 'with feed_url' do
        let(:item_attributes) do
          { feed_url: 'http://custom.feed.url/feed.rss' }
        end

        it 'returns custom URL' do
          expect(subject).to eql('http://custom.feed.url/feed.rss')
        end
      end

      context 'without feed_url' do
        it 'returns base URL + path' do
          expect(subject).to eql('http://url.base/feed.xml')
        end
      end
    end
  end

  describe '#attribute_to_time' do
    subject { mod.attribute_to_time(arg) }

    let(:around_noon_local) { Time.at(1446903076 - Time.now.utc_offset) }
    let(:around_noon_utc) { Time.at(1446903076) }
    let(:beginning_of_day_local) { Time.at(1446854400 - Time.now.utc_offset) }

    context 'with Time instance' do
      let(:arg) { around_noon_utc }
      it { is_expected.to eql(around_noon_utc) }
    end

    context 'with Date instance' do
      let(:arg) { Date.new(2015, 11, 7) }
      it { is_expected.to eql(beginning_of_day_local) }
    end

    context 'with DateTime instance' do
      let(:arg) { DateTime.new(2015, 11, 7, 13, 31, 16) }
      it { is_expected.to eql(around_noon_utc) }
    end

    context 'with string' do
      let(:arg) { '2015-11-7 13:31:16' }
      it { is_expected.to eql(around_noon_local) }
    end
  end

  describe '#atom_tag_for' do
    subject { mod.atom_tag_for(item_view) }

    let(:item) do
      Nanoc::Int::Item.new('Stuff', item_attributes, '/stuff/')
    end

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |rep|
        rep.paths[:last] = item_rep_path
      end
    end

    let(:item_rep_path) { '/stuff.xml' }

    let(:item_view) do
      Nanoc::ItemView.new(item, view_context)
    end

    let(:item_attributes) do
      { created_at: '2015-05-19 12:34:56' }
    end

    let(:assigns) do
      {
        config: { base_url: base_url },
        item: item_view,
      }
    end

    let(:base_url) { 'http://url.base' }

    before do
      reps << rep
    end

    context 'item with path' do
      let(:item_rep_path) { '/stuff.xml' }
      it { is_expected.to eql('tag:url.base,2015-05-19:/stuff.xml') }
    end

    context 'item without path' do
      let(:item_rep_path) { nil }
      it { is_expected.to eql('tag:url.base,2015-05-19:/stuff/') }
    end

    context 'bare URL without subdir' do
      let(:base_url) { 'http://url.base' }
      it { is_expected.to eql('tag:url.base,2015-05-19:/stuff.xml') }
    end

    context 'bare URL with subdir' do
      let(:base_url) { 'http://url.base/sub' }
      it { is_expected.to eql('tag:url.base,2015-05-19:/sub/stuff.xml') }
    end

    context 'created_at is date' do
      let(:item_attributes) do
        { created_at: Date.parse('2015-05-19 12:34:56') }
      end
      it { is_expected.to eql('tag:url.base,2015-05-19:/stuff.xml') }
    end

    context 'created_at is time' do
      let(:item_attributes) do
        { created_at: Time.parse('2015-05-19 12:34:56') }
      end
      it { is_expected.to eql('tag:url.base,2015-05-19:/stuff.xml') }
    end

    # TODO: handle missing base_dir
    # TODO: handle missing created_at
  end
end
