# frozen_string_literal: true

describe Nanoc::DataSource, stdio: true do
  subject(:data_source) do
    described_class.new({}, nil, nil, {})
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
