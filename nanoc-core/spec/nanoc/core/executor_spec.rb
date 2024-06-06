# frozen_string_literal: true

describe Nanoc::Core::Executor do
  Class.new(Nanoc::Core::Filter) do
    identifier :simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei

    def run(content, _params = {})
      context = Nanoc::Core::Context.new(assigns)
      ERB.new(content).result(context.get_binding)
    end
  end

  let(:executor) { described_class.new(rep, compilation_context, dependency_tracker) }

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider:,
      reps:,
      site:,
      compiled_content_cache:,
      compiled_content_store:,
    )
  end

  let(:item) { Nanoc::Core::Item.new(content, {}, '/index.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :donkey) }
  let(:content) { Nanoc::Core::TextualContent.new('Donkey Power').tap(&:freeze) }

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  let(:reps) do
    Nanoc::Core::ItemRepRepo.new
  end

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:layout) do
    Nanoc::Core::Layout.new(layout_content, { bug: 'Gum Emperor' }, '/default.erb')
  end

  let(:layouts) { Nanoc::Core::LayoutCollection.new(config, [layout]) }
  let(:items) { Nanoc::Core::ItemCollection.new(config, []) }

  let(:layout_content) { 'head <%= @content %> foot' }

  let(:config_hash) { { string_pattern_type: 'glob' } }
  let(:config) { Nanoc::Core::Configuration.new(hash: config_hash, dir: Dir.getwd).with_defaults }

  let(:compiled_content_cache) do
    Nanoc::Core::CompiledContentCache.new(config:)
  end

  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(double(:dependency_store)) }

  describe '#filter' do
    let(:assigns) { {} }

    let(:content) { Nanoc::Core::TextualContent.new('<%= "Donkey" %> Power') }

    context 'normal flow with textual rep' do
      subject { executor.filter(:simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei) }

      before do
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei)
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei)

        compiled_content_store.set_current(rep, content)
      end

      it 'does not set :pre in repo' do
        expect(compiled_content_store.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(compiled_content_store.get(rep, :post)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :post) }
      end

      it 'does not set :last in repo' do
        expect(compiled_content_store.get(rep, :last)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :last) }
      end

      it 'updates current content in repo' do
        expect { subject }
          .to change { compiled_content_store.get_current(rep).string }
          .from('<%= "Donkey" %> Power')
          .to('Donkey Power')
      end

      it 'returns frozen data' do
        executor.filter(:simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei)

        expect(compiled_content_store.get_current(rep)).to be_frozen
      end
    end

    context 'normal flow with binary rep' do
      subject { executor.filter(:whatever) }

      let(:content) { Nanoc::Core::BinaryContent.new(File.expand_path('foo.dat')) }

      before do
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        File.write(content.filename, 'Foo Data')

        filter_class = Class.new(Nanoc::Core::Filter) do
          type :binary

          def run(filename, _params = {})
            File.write(output_filename, "Compiled data for #{filename}")
          end
        end

        expect(Nanoc::Core::Filter).to receive(:named).with(:whatever) { filter_class }

        compiled_content_store.set_current(rep, content)
      end

      it 'does not set :pre in repo' do
        expect(compiled_content_store.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(compiled_content_store.get(rep, :post)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :post) }
      end

      it 'does not set :last in repo' do
        expect(compiled_content_store.get(rep, :last)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :last) }
      end

      it 'updates current content in repo' do
        expect { subject }
          .to change { File.read(compiled_content_store.get_current(rep).filename) }
          .from('Foo Data')
          .to(/\ACompiled data for (C:)?\/.*\/foo.dat\z/)
      end

      it 'returns frozen data' do
        executor.filter(:whatever)

        expect(compiled_content_store.get_current(rep)).to be_frozen
      end
    end

    context 'normal flow with binary rep and binary-to-text filter' do
      subject { executor.filter(:whatever) }

      let(:content) { Nanoc::Core::BinaryContent.new(File.expand_path('foo.dat')) }

      before do
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        File.write(content.filename, 'Foo Data')

        filter_class = Class.new(Nanoc::Core::Filter) do
          type binary: :text

          def run(filename, _params = {})
            "Compiled data for #{filename}"
          end
        end

        expect(Nanoc::Core::Filter).to receive(:named).with(:whatever) { filter_class }

        compiled_content_store.set_current(rep, content)
      end

      it 'does not set :pre in repo' do
        expect(compiled_content_store.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(compiled_content_store.get(rep, :post)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :post) }
      end

      it 'does not set :last in repo' do
        expect(compiled_content_store.get(rep, :last)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :last) }
      end

      it 'updates current content repo' do
        expect { subject }
          .to change { compiled_content_store.get_current(rep) }
          .from(some_binary_content('Foo Data'))
          .to(some_textual_content(/\ACompiled data for (C:)?\/.*\/foo.dat\z/))
      end
    end

    context 'normal flow with textual rep and text-to-binary filter' do
      subject { executor.filter(:whatever) }

      before do
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        filter_class = Class.new(Nanoc::Core::Filter) do
          type text: :binary

          def run(content, _params = {})
            File.write(output_filename, "Binary #{content}")
          end
        end

        expect(Nanoc::Core::Filter).to receive(:named).with(:whatever) { filter_class }

        compiled_content_store.set_current(rep, content)
      end

      it 'does not set :pre in repo' do
        expect(compiled_content_store.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(compiled_content_store.get(rep, :post)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :post) }
      end

      it 'does not set :last in repo' do
        expect(compiled_content_store.get(rep, :last)).to be_nil
        expect { subject }.not_to change { compiled_content_store.get(rep, :last) }
      end

      it 'updates current content in repo' do
        expect { subject }
          .to change { compiled_content_store.get_current(rep) }
          .from(some_textual_content('<%= "Donkey" %> Power'))
          .to(some_binary_content('Binary <%= "Donkey" %> Power'))
      end
    end

    context 'non-existant filter' do
      it 'raises' do
        expect { executor.filter(:ajlsdfjklaskldfj) }
          .to raise_error(Nanoc::Core::Filter::UnknownFilterError)
      end
    end

    context 'non-binary rep, binary-to-something filter' do
      before do
        filter_class = Class.new(Nanoc::Core::Filter) do
          type :binary

          def run(_content, _params = {}); end
        end

        expect(Nanoc::Core::Filter).to receive(:named).with(:whatever) { filter_class }

        compiled_content_store.set_current(rep, content)
      end

      it 'raises' do
        expect { executor.filter(:whatever) }
          .to raise_error(Nanoc::Core::Errors::CannotUseBinaryFilter)
      end
    end

    context 'binary rep, text-to-something filter' do
      let(:content) { Nanoc::Core::BinaryContent.new(File.expand_path('foo.md')) }

      before do
        compiled_content_store.set_current(rep, content)
      end

      it 'raises' do
        expect { executor.filter(:simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei) }
          .to raise_error(Nanoc::Core::Errors::CannotUseTextualFilter)
      end
    end

    context 'binary filter that does not write anything' do
      let(:content) { Nanoc::Core::BinaryContent.new(File.expand_path('foo.dat')) }

      before do
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Core::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        File.write(content.filename, 'Foo Data')

        filter_class = Class.new(Nanoc::Core::Filter) do
          identifier :executor_spec_Toing1Oowoa3aewoop0k
          type :binary

          def run(_filename, _params = {}); end
        end

        compiled_content_store.set_current(rep, content)

        expect(Nanoc::Core::Filter).to receive(:named).with(:whatever) { filter_class }
      end

      example do
        expect { executor.filter(:whatever) }
          .to raise_error(Nanoc::Core::Filter::OutputNotWrittenError)
      end
    end

    context 'content is frozen' do
      before do
        compiled_content_store.set_current(rep, item.content)
      end

      let(:item) do
        Nanoc::Core::Item.new('foo bar', {}, '/foo.md').tap(&:freeze)
      end

      let(:filter_that_modifies_content) do
        Class.new(Nanoc::Core::Filter) do
          def run(content, _params = {})
            content.gsub!('foo', 'moo')
            content
          end
        end
      end

      let(:filter_that_modifies_params) do
        Class.new(Nanoc::Core::Filter) do
          def run(_content, params = {})
            params[:foo] = 'bar'
            'asdf'
          end
        end
      end

      it 'errors when attempting to modify content' do
        expect(Nanoc::Core::Filter).to receive(:named).with(:whatever).and_return(filter_that_modifies_content)
        expect { executor.filter(:whatever) }.to raise_frozen_error
      end

      it 'receives frozen filter args' do
        expect(Nanoc::Core::Filter).to receive(:named).with(:whatever).and_return(filter_that_modifies_params)
        expect { executor.filter(:whatever) }.to raise_frozen_error
      end
    end
  end

  describe '#layout' do
    subject { executor.layout('/default.*') }

    let(:action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei, {})
      end
    end

    before do
      rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:pre, binary: false)]

      compiled_content_store.set_current(rep, content)

      allow(action_provider).to receive(:action_sequence_for).with(layout).and_return(action_sequence)
    end

    context 'accessing layout attributes' do
      let(:layout_content) { 'head <%= @layout[:bug] %> foot' }

      it 'exposes @layout as view' do
        allow(dependency_tracker).to receive(:enter)
          .with(layout, raw_content: true, attributes: false, compiled_content: false, path: false)
        allow(dependency_tracker).to receive(:enter)
          .with(layout, raw_content: false, attributes: [:bug], compiled_content: false, path: false)
        allow(dependency_tracker).to receive(:exit)
        subject
        expect(compiled_content_store.get_current(rep).string).to eq('head Gum Emperor foot')
      end
    end

    context 'normal flow' do
      it 'updates :last in repo' do
        expect { subject }
          .to change { compiled_content_store.get_current(rep) }
          .from(some_textual_content('Donkey Power'))
          .to(some_textual_content('head Donkey Power foot'))
      end

      it 'sets frozen content' do
        subject
        expect(compiled_content_store.get_current(rep)).to be_frozen
        expect(compiled_content_store.get(rep, :pre)).to be_frozen
      end

      it 'does not create pre snapshot' do
        # a #layout is followed by a #snapshot(:pre, …)
        expect(compiled_content_store.get(rep, :pre)).to be_nil
        subject
        expect(compiled_content_store.get(rep, :pre)).to be_nil
      end

      it 'sends notifications' do
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_started, rep, :simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei).ordered
        expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei).ordered

        subject
      end

      context 'compiled_content reference in layout' do
        let(:layout_content) { 'head <%= @item_rep.compiled_content(snapshot: :pre) %> foot' }

        let(:assigns) do
          { item_rep: Nanoc::Core::CompilationItemRepView.new(rep, view_context) }
        end

        before do
          executor.snapshot(:pre)
        end

        it 'does not set :last in repo' do
          expect(compiled_content_store.get(rep, :last)).to be_nil
          expect { subject }.not_to change { compiled_content_store.get(rep, :last) }
        end

        it 'updates current content in repo' do
          expect { subject }
            .to change { compiled_content_store.get_current(rep) }
            .from(some_textual_content('Donkey Power'))
            .to(some_textual_content('head Donkey Power foot'))
        end
      end

      context 'content with layout reference' do
        let(:layout_content) { 'head <%= @layout.identifier %> foot' }

        it 'does not set :last in repo' do
          expect(compiled_content_store.get(rep, :last)).to be_nil
          expect { subject }.not_to change { compiled_content_store.get(rep, :last) }
        end

        it 'updates current content in repo' do
          expect { subject }
            .to change { compiled_content_store.get_current(rep) }
            .from(some_textual_content('Donkey Power'))
            .to(some_textual_content('head /default.erb foot'))
        end
      end
    end

    context 'no layout found' do
      let(:layouts) do
        Nanoc::Core::LayoutCollection.new(
          config,
          [Nanoc::Core::Layout.new('head <%= @foo %> foot', {}, '/other.erb')],
        )
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Core::Errors::UnknownLayout)
      end
    end

    context 'no filter specified' do
      let(:action_sequence) do
        Nanoc::Core::ActionSequence.new
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Core::CompilationContext::UndefinedFilterForLayoutError)
      end
    end

    context 'binary item' do
      let(:content) { Nanoc::Core::BinaryContent.new(File.expand_path('donkey.md')) }

      it 'raises' do
        expect { subject }.to raise_error(
          Nanoc::Core::Errors::CannotLayoutBinaryItem,
          'The “/index.md” item (rep “donkey”) cannot be laid out because it is a binary item. If you are getting this error for an item that should be textual instead of binary, make sure that its extension is included in the text_extensions array in the site configuration.',
        )
      end
    end

    it 'receives frozen filter args' do
      filter_class = Class.new(Nanoc::Core::Filter) do
        def run(_content, params = {})
          params[:foo] = 'bar'
          'asdf'
        end
      end

      expect(Nanoc::Core::Filter).to receive(:named).with(:simple_erb_uy2wbp6dcf4hlc4gbluauh07zuz2wvei) { filter_class }

      expect { subject }.to raise_frozen_error
    end
  end

  describe '#snapshot' do
    subject { executor.snapshot(:something) }

    before do
      compiled_content_store.set_current(rep, content)

      File.write('donkey.dat', 'binary donkey')
    end

    context 'binary content' do
      let(:content) { Nanoc::Core::BinaryContent.new(File.expand_path('donkey.dat')) }

      it 'creates snapshots in repo' do
        expect { subject }
          .to change { compiled_content_store.get(rep, :something) }
          .from(nil)
          .to(some_binary_content('binary donkey'))
      end
    end

    context 'textual content' do
      let(:content) { Nanoc::Core::TextualContent.new('Donkey Power') }

      it 'creates snapshots in repo' do
        expect { subject }
          .to change { compiled_content_store.get(rep, :something) }
          .from(nil)
          .to(some_textual_content('Donkey Power'))
      end
    end

    context 'final snapshot' do
      let(:content) { Nanoc::Core::TextualContent.new('Donkey Power') }

      context 'raw path' do
        before do
          rep.raw_paths = { something: [Dir.getwd + '/output/donkey.md'] }
        end

        it 'does not write' do
          executor.snapshot(:something)

          expect(File.file?('output/donkey.md')).to be(false)
        end
      end

      context 'no raw path' do
        it 'does not write' do
          executor.snapshot(:something)

          expect(File.file?('output/donkey.md')).to be(false)
        end
      end
    end
  end

  describe '#find_layout' do
    subject { executor.find_layout(arg) }

    before do
      allow(compilation_context).to receive(:site) { site }
    end

    context 'layout with cleaned identifier exists' do
      let(:arg) { '/default' }

      let(:layouts) do
        Nanoc::Core::LayoutCollection.new(
          config,
          [Nanoc::Core::Layout.new('head <%= @foo %> foot', {}, Nanoc::Core::Identifier.new('/default/', type: :legacy))],
        )
      end

      it { is_expected.to eq(layouts.to_a[0]) }
    end

    context 'no layout with cleaned identifier exists' do
      let(:layouts) do
        Nanoc::Core::LayoutCollection.new(
          config,
          [Nanoc::Core::Layout.new('head <%= @foo %> foot', {}, '/default.erb')],
        )
      end

      context 'globs' do
        let(:config_hash) { { string_pattern_type: 'glob' } }

        let(:arg) { '/default.*' }

        it { is_expected.to eq(layouts.to_a[0]) }
      end

      context 'no globs' do
        let(:config_hash) { { string_pattern_type: 'legacy' } }

        let(:arg) { '/default.*' }

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Core::Errors::UnknownLayout)
        end
      end
    end
  end
end
