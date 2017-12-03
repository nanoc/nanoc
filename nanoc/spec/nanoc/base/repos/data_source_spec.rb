# frozen_string_literal: true

describe Nanoc::DataSource, stdio: true do
  subject(:data_source) do
    described_class.new({}, nil, nil, {})
  end

  it 'has an empty #up implementation' do
    data_source.up
  end

  it 'has an empty #down implementation' do
    data_source.down
  end

  it 'returns empty #items' do
    expect(data_source.items).to be_empty
  end

  it 'returns empty #layouts' do
    expect(data_source.layouts).to be_empty
  end

  describe '#new_item' do
    it 'supports checksum data' do
      item = data_source.new_item('stuff', { title: 'Stuff!' }, '/asdf', checksum_data: 'abcdef')

      expect(item.content.string).to eql('stuff')
      expect(item.attributes[:title]).to eql('Stuff!')
      expect(item.identifier).to eql(Nanoc::Identifier.new('/asdf'))
      expect(item.checksum_data).to eql('abcdef')
    end

    it 'supports content/attributes checksum data' do
      item = data_source.new_item('stuff', { title: 'Stuff!' }, '/asdf', content_checksum_data: 'con-cs', attributes_checksum_data: 'attr-cs')

      expect(item.content.string).to eql('stuff')
      expect(item.attributes[:title]).to eql('Stuff!')
      expect(item.identifier).to eql(Nanoc::Identifier.new('/asdf'))
      expect(item.content_checksum_data).to eql('con-cs')
      expect(item.attributes_checksum_data).to eql('attr-cs')
    end
  end

  describe '#new_layout' do
    it 'supports checksum data' do
      layout = data_source.new_layout('stuff', { title: 'Stuff!' }, '/asdf', checksum_data: 'abcdef')

      expect(layout.content.string).to eql('stuff')
      expect(layout.attributes[:title]).to eql('Stuff!')
      expect(layout.identifier).to eql(Nanoc::Identifier.new('/asdf'))
      expect(layout.checksum_data).to eql('abcdef')
    end

    it 'supports content/attributes checksum data' do
      layout = data_source.new_layout('stuff', { title: 'Stuff!' }, '/asdf', content_checksum_data: 'con-cs', attributes_checksum_data: 'attr-cs')

      expect(layout.content.string).to eql('stuff')
      expect(layout.attributes[:title]).to eql('Stuff!')
      expect(layout.identifier).to eql(Nanoc::Identifier.new('/asdf'))
      expect(layout.content_checksum_data).to eql('con-cs')
      expect(layout.attributes_checksum_data).to eql('attr-cs')
    end
  end

  describe '#item_changes' do
    subject { data_source.item_changes }

    it 'warns' do
      expect { subject }.to output("Caution: Data source nil does not implement #item_changes; live compilation will not pick up changes in this data source.\n").to_stderr
    end

    it 'never yields anything' do
      q = SizedQueue.new(1)
      Thread.new { subject.each { |c| q << c } }
      sleep 0.1
      expect { q.pop(true) }.to raise_error(ThreadError)
    end
  end

  describe '#layout_changes' do
    subject { data_source.layout_changes }

    it 'warns' do
      expect { subject }.to output("Caution: Data source nil does not implement #layout_changes; live compilation will not pick up changes in this data source.\n").to_stderr
    end

    it 'never yields anything' do
      q = SizedQueue.new(1)
      Thread.new { subject.each { |c| q << c } }
      sleep 0.1
      expect { q.pop(true) }.to raise_error(ThreadError)
    end
  end
end
