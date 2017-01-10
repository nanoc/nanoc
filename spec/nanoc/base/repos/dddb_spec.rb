require 'tmpdir'

describe Nanoc::Int::DDDB do
  it 'has no data by default' do
    db = described_class.new('donkey')
    db.open

    expect(db['a']).to be_nil
    expect(db['b']).to be_nil
  end

  it 'can insert data' do
    db = described_class.new('donkey')
    db.open
    db['a'] = 'value for a'

    expect(db['a']).to eq('value for a')
    expect(db['b']).to be_nil
  end

  it 'persists data' do
    db = described_class.new('donkey')
    db.open
    db['a'] = 'value for a'
    db.close

    db = described_class.new('donkey')
    db.open

    expect(db['a']).to eq('value for a')
    expect(db['b']).to be_nil
  end

  describe '#key? and #eys' do
    context 'key exists' do
      it 'is true' do
        db = described_class.new('donkey')
        db.open
        db['a'] = 'value for a'
        expect(db.key?('a')).to be
        expect(db.keys).to eq(['a'])
      end
    end

    context 'key does not exist' do
      it 'is false' do
        db = described_class.new('donkey')
        db.open
        expect(db.key?('a')).not_to be
        expect(db.keys).to be_empty
      end
    end
  end

  describe '#delete' do
    context 'key exists' do
      example do
        db = described_class.new('donkey')
        db.open
        db['a'] = 'value for a'
        expect(db.key?('a')).to be
        db.delete('a')
        expect(db.key?('a')).not_to be
      end
    end

    context 'key does not exist' do
      example do
        db = described_class.new('donkey')
        db.open
        expect(db.key?('a')).not_to be
        db.delete('a')
        expect(db.key?('a')).not_to be
      end
    end
  end

  describe '#compact' do
    it 'does not change existing values' do
      db = described_class.new('donkey')
      db.open

      db['a'] = 'value for a'
      db['b'] = 'value for b'

      expect(db['a']).to eq('value for a')
      expect(db['b']).to eq('value for b')

      db.delete('a')

      expect(db['a']).to be_nil
      expect(db['b']).to eq('value for b')

      expect { db.compact }
        .to change { File.read('donkey.db') }
        .from("\u0000\u0000\u0000\vvalue for a\u0000\u0000\u0000\vvalue for b")
        .to("\u0000\u0000\u0000\vvalue for b")

      expect(db['a']).to be_nil
      expect(db['b']).to eq('value for b')
    end

    it 'supports adding/fetching afterwards' do
      db = described_class.new('donkey')
      db.open
      db['a'] = 'value for a'
      db['b'] = 'value for b'
      db.delete('a')

      db.compact

      db['c'] = 'value for c'
      expect(db['a']).to be_nil
      expect(db['b']).to eq('value for b')
      expect(db['c']).to eq('value for c')
    end
  end
end
