# frozen_string_literal: true

describe Nanoc::Helpers::Blogging, helper: true do
  before do
    allow(ctx.dependency_tracker).to receive(:enter)
    allow(ctx.dependency_tracker).to receive(:exit)
  end

  describe '#articles' do
    subject { helper.articles }

    before do
      ctx.create_item('blah', { kind: 'item' }, '/0/')
      ctx.create_item('blah blah', { kind: 'article' }, '/1/')
      ctx.create_item('blah blah blah', { kind: 'article' }, '/2/')
    end

    it 'returns the two articles' do
      expect(subject.map(&:identifier)).to match_array(['/1/', '/2/'])
    end
  end

  describe '#sorted_articles' do
    subject { helper.sorted_articles }

    before do
      attrs = { kind: 'item' }
      ctx.create_item('blah', attrs, '/0/')

      attrs = { kind: 'article', created_at: (Date.today - 1).to_s }
      ctx.create_item('blah blah', attrs, '/1/')

      attrs = { kind: 'article', created_at: (Time.now - 500).to_s }
      ctx.create_item('blah blah blah', attrs, '/2/')
    end

    it 'returns the two articles in descending order' do
      expect(subject.map(&:identifier)).to eq(['/2/', '/1/'])
    end
  end

  describe '#url_for' do
    subject { helper.url_for(ctx.items['/stuff/']) }

    let(:item_attributes) { {} }

    before do
      ctx.create_item('Stuff', item_attributes, '/stuff/')
      ctx.create_rep(ctx.items['/stuff/'], '/rep/path/stuff.html')

      ctx.config[:base_url] = base_url
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
    subject { helper.feed_url }

    let(:item_attributes) { {} }

    before do
      ctx.create_item('Feed', item_attributes, '/feed/')
      ctx.create_rep(ctx.items['/feed/'], '/feed.xml')

      ctx.item = ctx.items['/feed/']
      ctx.config[:base_url] = base_url
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
    subject { helper.attribute_to_time(arg) }

    let(:noon_s) { 1_446_903_076 }
    let(:beginning_of_day_s) { 1_446_854_400 }

    let(:around_noon_local) { Time.at(noon_s - Time.at(noon_s).utc_offset) }
    let(:around_noon_utc) { Time.at(noon_s) }
    let(:beginning_of_day_utc) { Time.at(beginning_of_day_s) }

    context 'with Time instance' do
      let(:arg) { around_noon_utc }
      it { is_expected.to eql(around_noon_utc) }
    end

    context 'with Date instance' do
      let(:arg) { Date.new(2015, 11, 7) }
      it { is_expected.to eql(beginning_of_day_utc) }
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
    subject { helper.atom_tag_for(ctx.items['/stuff/']) }

    let(:item_attributes) { { created_at: '2015-05-19 12:34:56' } }
    let(:item_rep_path) { '/stuff.xml' }
    let(:base_url) { 'http://url.base' }

    before do
      ctx.create_item('Stuff', item_attributes, '/stuff/')
      ctx.create_rep(ctx.items['/stuff/'], item_rep_path)

      ctx.config[:base_url] = base_url
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
