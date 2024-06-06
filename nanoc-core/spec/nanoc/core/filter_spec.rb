# frozen_string_literal: true

describe Nanoc::Core::Filter do
  describe '.define' do
    context 'simple filter' do
      let(:filter_name) { :b5355bbb4d772b9853d21be57da614dba521dbbb }
      let(:filter_class) { described_class.named(filter_name) }

      before do
        described_class.define(filter_name) do |content, _params|
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
      let(:filter_name) { :d7ed105d460e99a3d38f46af023d9490c140fdd9 }
      let(:filter_class) { described_class.named(filter_name) }
      let(:filter) { filter_class.new(assigns) }
      let(:assigns) { { animal: 'Giraffe' } }

      before do
        described_class.define(filter_name) do |_content, _params|
          @animal
        end
      end

      it 'can access assigns' do
        expect(filter.setup_and_run(:__irrelevant__, {})).to eq('Giraffe')
      end
    end
  end

  describe '.named!' do
    let(:filter_name) { :ipk5rpblmorrrgkiodzuuanfujokae2g }
    let(:filter_class) { described_class.named(filter_name) }

    before do
      described_class.define(filter_name) do |content, _params|
        content.upcase
      end
    end

    it 'returns filter if exists' do
      expect(described_class.named!(filter_name)).not_to be_nil
      expect(described_class.named!(filter_name).identifier).to eq(filter_name)
    end

    it 'raises if non-existent' do
      expect { described_class.named!(:ajklsdfklasjflkd) }
        .to raise_error(
          Nanoc::Core::Filter::UnknownFilterError,
          'The requested filter, “ajklsdfklasjflkd”, does not exist.',
        )
    end
  end

  describe 'assigns' do
    context 'no assigns given' do
      subject { described_class.new }

      it 'has empty assigns' do
        expect(subject.instance_eval { @assigns }).to eq({})
      end
    end

    context 'assigns given' do
      subject { described_class.new(foo: 'bar') }

      it 'has assigns' do
        expect(subject.instance_eval { @assigns }).to eq(foo: 'bar')
      end

      it 'can access assigns with @' do
        expect(subject.instance_eval { @foo }).to eq('bar')
      end

      it 'can access assigns without @' do
        expect(subject.instance_eval { foo }).to eq('bar')
      end
    end
  end

  describe '#run' do
    context 'no subclass' do
      subject { described_class.new.run('stuff') }

      it 'errors' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end

    context 'subclass' do
      # TODO
    end
  end

  describe '#filename' do
    subject { described_class.new(assigns).filename }

    context 'assigns contains item + item rep' do
      let(:item) { Nanoc::Core::Item.new('asdf', {}, '/donkey.md') }
      let(:item_rep) { Nanoc::Core::ItemRep.new(item, :animal) }
      let(:assigns) { { item:, item_rep: } }

      it { is_expected.to eq('item /donkey.md (rep animal)') }
    end

    context 'assigns contains layout' do
      let(:layout) { Nanoc::Core::Layout.new('asdf', {}, '/donkey.md') }
      let(:assigns) { { layout: } }

      it { is_expected.to eq('layout /donkey.md') }
    end

    context 'assigns contains neither' do
      let(:assigns) { {} }

      it { is_expected.to eq('?') }
    end
  end

  describe '.always_outdated? + .always_outdated' do
    context 'not always outdated' do
      let(:filter_class) do
        Class.new(Nanoc::Core::Filter) do
          identifier :bea22a356b6b031cea1e615087179803818c6a53

          def run(content, _params)
            content.upcase
          end
        end
      end

      it 'is not always outdated' do
        expect(filter_class).not_to be_always_outdated
      end
    end

    context 'always outdated' do
      let(:filter_class) do
        Class.new(Nanoc::Core::Filter) do
          identifier :d7413fa71223e5e69b03a0abfa25806e07e14f3a

          always_outdated

          def run(content, _params)
            content.upcase
          end
        end
      end

      it 'is always outdated' do
        expect(filter_class).to be_always_outdated
      end
    end
  end

  describe '#depend_on' do
    subject { filter.depend_on(item_views) }

    before do
      described_class.define(filter_name) do |content, _params|
        content.upcase
      end
    end

    let(:filter_name) { :z3xe2lejsgmuaa57jrfapvlkitgi1vwl }
    let(:filter_class) { described_class.named(filter_name) }

    let(:filter) { filter_class.new(assigns) }
    let(:item_views) { [item_view] }

    let(:item) { Nanoc::Core::Item.new('foo', {}, '/stuff.md') }
    let(:item_view) { Nanoc::Core::CompilationItemView.new(item, view_context) }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

    let(:view_context) do
      Nanoc::Core::ViewContextForCompilation.new(
        reps:,
        items: Nanoc::Core::ItemCollection.new(config),
        dependency_tracker:,
        compilation_context:,
        compiled_content_store:,
      )
    end

    let(:compilation_context) do
      Nanoc::Core::CompilationContext.new(
        action_provider:,
        reps:,
        site:,
        compiled_content_cache:,
        compiled_content_store:,
      )
    end

    let(:action_provider) do
      Class.new(Nanoc::Core::ActionProvider) do
        def self.for(_context)
          raise NotImplementedError
        end

        def initialize; end
      end.new
    end

    let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }
    let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }

    let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(dependency_store) }
    let(:dependency_store) { Nanoc::Core::DependencyStore.new(empty_items, empty_layouts, config) }

    let(:empty_items) { Nanoc::Core::ItemCollection.new(config) }
    let(:empty_layouts) { Nanoc::Core::LayoutCollection.new(config) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

    let(:reps) { Nanoc::Core::ItemRepRepo.new }

    let(:site) do
      Nanoc::Core::Site.new(
        config:,
        code_snippets: [],
        data_source: Nanoc::Core::InMemoryDataSource.new(empty_items, empty_layouts),
      )
    end

    let(:assigns) do
      {
        item: item_view,
      }
    end

    context 'reps exist' do
      before { reps << rep }

      context 'rep is compiled' do
        before do
          rep.compiled = true
        end

        example do
          expect { subject }.not_to yield_from_fiber(an_instance_of(Nanoc::Core::Errors::UnmetDependency))
        end

        it 'creates dependency' do
          expect { subject }
            .to create_dependency_on(item_view)
        end
      end

      context 'rep is not compiled' do
        example do
          fiber = Fiber.new { subject }

          # resume 1
          res = fiber.resume
          expect(res).to be_a(Nanoc::Core::Errors::UnmetDependency)
          expect(res.rep).to eql(rep)

          # resume 2
          expect(fiber.resume).not_to be_a(Nanoc::Core::Errors::UnmetDependency)
        end
      end

      context 'multiple reps exist' do
        let(:other_rep) { Nanoc::Core::ItemRep.new(item, :default) }

        before do
          reps << other_rep
          rep.compiled = false
          other_rep.compiled = false
        end

        it 'yields an unmet dependency error twice' do
          fiber = Fiber.new { subject }

          # resume 1
          res = fiber.resume
          expect(res).to be_a(Nanoc::Core::Errors::UnmetDependency)
          expect(res.rep).to eql(rep)

          # resume 2
          res = fiber.resume
          expect(res).to be_a(Nanoc::Core::Errors::UnmetDependency)
          expect(res.rep).to eql(other_rep)

          # resume 3
          expect(fiber.resume).not_to be_a(Nanoc::Core::Errors::UnmetDependency)
        end
      end
    end

    context 'no reps exist' do
      context 'textual' do
        it 'creates dependency' do
          expect { subject }
            .to create_dependency_on(item_view)
        end
      end

      context 'binary' do
        let(:item) { Nanoc::Core::Item.new(content, {}, '/stuff.md') }

        let(:filename) { File.expand_path('foo.dat') }
        let(:content) { Nanoc::Core::BinaryContent.new(filename) }

        it 'creates dependency' do
          expect { subject }
            .to create_dependency_on(item_view)
        end
      end
    end
  end
end
