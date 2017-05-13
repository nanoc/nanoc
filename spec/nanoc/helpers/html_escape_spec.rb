# frozen_string_literal: true

describe Nanoc::Helpers::HTMLEscape, helper: true do
  describe '#html_escape' do
    subject { helper.html_escape(string) }

    context 'given strings to escape' do
      let(:string) { '< > & "' }
      it { is_expected.to eql('&lt; &gt; &amp; &quot;') }
    end

    context 'given a block' do
      let!(:_erbout) { String.new('moo') }

      it 'adds escaped content to _erbout' do
        helper.html_escape { _erbout << '<h1>Stuff!</h1>' }
        expect(_erbout).to eql('moo&lt;h1&gt;Stuff!&lt;/h1&gt;')
      end
    end

    context 'given no argument nor block' do
      subject { helper.html_escape }

      it 'raises' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'given argument that is not a string' do
      let(:string) { 1 }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end
end
