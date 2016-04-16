describe Nanoc::Filter do
  describe '.define' do
    before do
      Nanoc::Filter.define(:nanoc_filter_define_sample) do |content, _params|
        content.upcase
      end
    end

    it 'defines a filter' do
      expect(Nanoc::Filter.named(:nanoc_filter_define_sample)).not_to be_nil
    end

    it 'defines a callable filter' do
      expect(Nanoc::Filter.named(:nanoc_filter_define_sample).new.run('foo', {})).to eql('FOO')
    end
  end
end
