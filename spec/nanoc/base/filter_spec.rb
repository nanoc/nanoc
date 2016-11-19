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

  describe '#depend_on' do
    subject { filter.depend_on(item_views) }

    let(:filter) { Nanoc::Filters::ERB.new(assigns) }
    let(:item_views) { [item_view] }

    let(:item) { Nanoc::Int::Item.new('foo', {}, '/stuff.md') }
    let(:item_view) { Nanoc::ItemWithRepsView.new(item, view_context) }
    let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }

    let(:view_context) do
      Nanoc::ViewContext.new(
        reps: reps,
        items: double(:items),
        dependency_tracker: dependency_tracker,
        compiler: double(:compiler),
      )
    end

    let(:dependency_tracker) { double(:dependency_tracker) }

    let(:reps) { Nanoc::Int::ItemRepRepo.new }

    let(:assigns) do
      {
        item: item_view,
      }
    end

    before do
      reps << rep

      expect(dependency_tracker).to receive(:bounce)
        .with(item, raw_content: true, attributes: true, compiled_content: true, path: true)
    end

    context 'rep is compiled' do
      before do
        rep.compiled = true
      end

      example do
        fiber = Fiber.new { subject }

        # resume 1
        expect(fiber.resume).not_to be_a(Nanoc::Int::Errors::UnmetDependency)
      end
    end

    context 'rep is not compiled' do
      example do
        fiber = Fiber.new { subject }

        # resume 1
        res = fiber.resume
        expect(res).to be_a(Nanoc::Int::Errors::UnmetDependency)
        expect(res.rep).to eql(rep)

        # resume 2
        expect(fiber.resume).not_to be_a(Nanoc::Int::Errors::UnmetDependency)
      end
    end
  end
end
