# frozen_string_literal: true

describe Nanoc::ConfigView do
  let(:config) do
    Nanoc::Int::Configuration.new(hash: hash)
  end

  let(:hash) { { amount: 9000, animal: 'donkey' } }

  let(:view) { described_class.new(config, nil) }

  describe '#frozen?' do
    subject { view.frozen? }

    context 'non-frozen config' do
      it { is_expected.to be(false) }
    end

    context 'frozen config' do
      before { config.freeze }
      it { is_expected.to be(true) }
    end
  end

  describe '#[]' do
    subject { view[key] }

    context 'with existant key' do
      let(:key) { :animal }
      it { is_expected.to eql('donkey') }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }
      it { is_expected.to eql(nil) }
    end
  end

  describe '#fetch' do
    context 'with existant key' do
      let(:key) { :animal }

      subject { view.fetch(key) }

      it { is_expected.to eql('donkey') }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      context 'with fallback' do
        subject { view.fetch(key, 'nothing sorry') }
        it { is_expected.to eql('nothing sorry') }
      end

      context 'with block' do
        subject { view.fetch(key) { 'nothing sorry' } }
        it { is_expected.to eql('nothing sorry') }
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
    subject { view.key?(key) }

    context 'with existant key' do
      let(:key) { :animal }
      it { is_expected.to eql(true) }
    end

    context 'with non-existant key' do
      let(:key) { :weapon }
      it { is_expected.to eql(false) }
    end
  end

  describe '#each' do
    example do
      res = []
      view.each { |k, v| res << [k, v] }

      expect(res).to eql([[:amount, 9000], [:animal, 'donkey']])
    end
  end

  describe '#inspect' do
    subject { view.inspect }
    it { is_expected.to eql('<Nanoc::ConfigView>') }
  end
end
