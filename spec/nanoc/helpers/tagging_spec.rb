# frozen_string_literal: true

describe Nanoc::Helpers::Tagging, helper: true do
  describe '#tags_for' do
    subject { helper.tags_for(item, params) }

    let(:item) { ctx.items['/me.*'] }
    let(:params) { {} }
    let(:item_attributes) { {} }

    before do
      ctx.create_item('content', item_attributes, '/me.md')
    end

    context 'no tags' do
      let(:item_attributes) { {} }
      it { is_expected.to eql('(none)') }
    end

    context 'nil tag list' do
      let(:item_attributes) { { tags: nil } }
      it { is_expected.to eql('(none)') }
    end

    context 'empty tag list' do
      let(:item_attributes) { { tags: [] } }
      it { is_expected.to eql('(none)') }
    end

    context 'no tags, and custom none text' do
      let(:item_attributes) { {} }
      let(:params) { { none_text: 'no tags for you, fool' } }
      it { is_expected.to eql('no tags for you, fool') }
    end

    context 'one tag' do
      let(:item_attributes) { { tags: %w[donkey] } }

      context 'implicit base_url' do
        it { is_expected.to eql('donkey') }
      end

      context 'explicit nil base_url' do
        let(:params) { { base_url: nil } }
        it { is_expected.to eql('donkey') }
      end

      context 'explicit other base_url' do
        let(:params) { { base_url: 'http://nanoc.ws/tag/' } }
        it { is_expected.to eql('<a href="http://nanoc.ws/tag/donkey" rel="tag">donkey</a>') }
      end
    end

    context 'two tags' do
      let(:item_attributes) { { tags: %w[donkey giraffe] } }
      it { is_expected.to eql('donkey, giraffe') }
    end

    context 'three tags' do
      let(:item_attributes) { { tags: %w[donkey giraffe zebra] } }
      it { is_expected.to eql('donkey, giraffe, zebra') }

      context 'custom separator' do
        let(:item_attributes) { { tags: %w[donkey giraffe zebra] } }
        let(:params) { { separator: ' / ' } }
        it { is_expected.to eql('donkey / giraffe / zebra') }
      end
    end
  end

  describe '#items_with_tag' do
    subject { helper.items_with_tag(tag) }

    before do
      ctx.create_item('item 1', { tags: [:foo] }, '/item1.md')
      ctx.create_item('item 2', { tags: [:bar] }, '/item2.md')
      ctx.create_item('item 3', { tags: %i[foo bar] }, '/item3.md')
      ctx.create_item('item 4', { tags: nil }, '/item4.md')
      ctx.create_item('item 5', {}, '/item5.md')
    end

    context 'tag that exists' do
      let(:tag) { :foo }
      it { is_expected.to contain_exactly(ctx.items['/item1.md'], ctx.items['/item3.md']) }
    end

    context 'tag that does not exists' do
      let(:tag) { :other }
      it { is_expected.to be_empty }
    end
  end

  describe '#link_for_tag' do
    subject { helper.link_for_tag(tag, base_url) }

    let(:tag) { 'foo' }
    let(:base_url) { 'http://nanoc.ws/tag/' }

    it { is_expected.to eql('<a href="http://nanoc.ws/tag/foo" rel="tag">foo</a>') }

    context 'tag with special HTML characters' do
      let(:tag) { 'R&D' }
      it { is_expected.to eql('<a href="http://nanoc.ws/tag/R&amp;D" rel="tag">R&amp;D</a>') }
    end
  end
end
