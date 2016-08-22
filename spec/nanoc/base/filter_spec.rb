describe Nanoc::Filter do
  describe '.define' do
    context 'simple filter' do
      let(:filter_name) { 'b5355bbb4d772b9853d21be57da614dba521dbbb' }
      let(:filter_class) { Nanoc::Filter.named(filter_name) }

      before do
        Nanoc::Filter.define(filter_name) do |content, _params|
          content.upcase
        end
      end

      it 'defines a filter' do
        expect(filter_class).not_to be_nil
      end

      it 'defines a callable filter' do
        expect(filter_class.new.run('foo', {})).to eql('FOO')
      end
    end

    context 'filter that accesses assigns' do
      let(:filter_name) { 'd7ed105d460e99a3d38f46af023d9490c140fdd9' }
      let(:filter_class) { Nanoc::Filter.named(filter_name) }
      let(:filter) { filter_class.new(assigns) }
      let(:assigns) { { animal: 'Giraffe' } }

      before do
        Nanoc::Filter.define(filter_name) do |_content, _params|
          @animal
        end
      end

      it 'can access assigns' do
        expect(filter.setup_and_run(:__irrelevant__, {})).to eq('Giraffe')
      end
    end
  end
end
