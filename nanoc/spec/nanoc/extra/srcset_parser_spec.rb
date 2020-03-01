# frozen_string_literal: true

describe Nanoc::Extra::SrcsetParser do
  subject(:parsed) { described_class.new(value).call }

  let(:value) { 'http://example.com/a.jpg' }

  test_cases = {
    'http://example.com/a.jpg 2w 3x' =>
      [{ url: 'http://example.com/a.jpg', rest: ' 2w 3x' }],

    'http://example.com/a.jpg 2w' =>
      [{ url: 'http://example.com/a.jpg', rest: ' 2w' }],

    'http://example.com/a.jpg 2w 2w 2w 2w 2w' =>
      [{ url: 'http://example.com/a.jpg', rest: ' 2w 2w 2w 2w 2w' }],

    'http://example.com/a.jpg 123456x' =>
      [{ url: 'http://example.com/a.jpg', rest: ' 123456x' }],

    '   http://example.com/a.jpg 2w 3x   ' =>
      [{ url: 'http://example.com/a.jpg', rest: ' 2w 3x' }],

    '   http://example.com/a.jpg 2w 3x  , http://example.com/b.jpg  4x 4x 5w  ' =>
      [{ url: 'http://example.com/a.jpg', rest: ' 2w 3x' }, { url: 'http://example.com/b.jpg', rest: '  4x 4x 5w' }],
  }

  test_cases.each do |input, expected_output|
    context "with #{input}" do
      let(:value) { input }

      it 'parses properly' do
        expect(parsed).to eq(expected_output)
      end
    end
  end
end
