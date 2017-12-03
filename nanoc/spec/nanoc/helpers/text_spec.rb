# frozen_string_literal: true

describe Nanoc::Helpers::Text, helper: true do
  describe '#excerptize' do
    subject { helper.excerptize(string, params) }

    let(:string) { 'Foo bar baz quux meow woof' }
    let(:params) { {} }

    context 'no params' do
      it 'takes 25 characters' do
        expect(subject).to eql('Foo bar baz quux meow ...')
      end
    end

    context 'perfect fit' do
      let(:params) { { length: 26 } }

      it 'does not truncate' do
        expect(subject).to eql('Foo bar baz quux meow woof')
      end
    end

    context 'long length' do
      let(:params) { { length: 27 } }

      it 'does not truncate' do
        expect(subject).to eql('Foo bar baz quux meow woof')
      end
    end

    context 'short length' do
      let(:params) { { length: 3 } }

      it 'truncates' do
        expect(subject).to eql('...')
      end
    end

    context 'length shorter than omission' do
      let(:params) { { length: 2 } }

      it 'truncates, disregarding length' do
        expect(subject).to eql('...')
      end
    end

    context 'custom omission' do
      let(:params) { { omission: '[continued]' } }

      it 'uses custom omission string' do
        expect(subject).to eql('Foo bar baz qu[continued]')
      end
    end
  end

  describe '#strip_html' do
    # TODO: test this… or get rid of it (it’s bad!)
  end
end
