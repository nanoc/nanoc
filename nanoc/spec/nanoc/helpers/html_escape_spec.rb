# frozen_string_literal: true

describe Nanoc::Helpers::HTMLEscape, helper: true do
  describe '#html_escape' do
    subject { helper.html_escape(string) }

    context 'when given angular brackets' do
      let(:string) { '<br/>' }

      it { is_expected.to eql('&lt;br/&gt;') }
    end

    context 'when given ampersand' do
      let(:string) { 'red & blue' }

      it { is_expected.to eql('red &amp; blue') }
    end

    context 'when given double quotes' do
      let(:string) { 'projection="isometric"' }

      it { is_expected.to eql('projection=&quot;isometric&quot;') }
    end

    context 'when given single quotes' do
      let(:string) { "projection='perspective'" }

      it { is_expected.to eql('projection=&#39;perspective&#39;') }
    end

    context 'given a block' do
      let!(:_erbout) { +'moo' }

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
