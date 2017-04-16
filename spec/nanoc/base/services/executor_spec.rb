describe Nanoc::Int::Executor do
  let(:executor) { described_class.new(rep, compilation_context, dependency_tracker) }

  let(:compilation_context) do
    Nanoc::Int::CompilationContext.new(
      action_provider: action_provider,
      reps: reps,
      site: site,
      compiled_content_cache: compiled_content_cache,
      snapshot_repo: snapshot_repo,
    )
  end

  let(:item) { Nanoc::Int::Item.new(content, {}, '/index.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :donkey) }
  let(:content) { Nanoc::Int::TextualContent.new('Donkey Power').tap(&:freeze) }

  let(:action_provider) { double(:action_provider) }
  let(:reps) { double(:reps) }
  let(:site) { double(:site) }
  let(:compiled_content_cache) { double(:compiled_content_cache) }
  let(:snapshot_repo) { Nanoc::Int::SnapshotRepo.new }

  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }

  describe '#filter' do
    let(:assigns) { {} }

    let(:content) { Nanoc::Int::TextualContent.new('<%= "Donkey" %> Power') }

    before do
      allow(compilation_context).to receive(:assigns_for) { assigns }
    end

    context 'normal flow with textual rep' do
      subject { executor.filter(:erb) }

      before do
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :erb)
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :erb)

        snapshot_repo.set(rep, :last, content)
      end

      it 'does not set :pre on rep' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post on rep' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last on rep' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last).string }
          .from('<%= "Donkey" %> Power')
          .to('Donkey Power')
      end

      it 'does not set :pre in repo' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last in repo' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last).string }
          .from('<%= "Donkey" %> Power')
          .to('Donkey Power')
      end

      it 'returns frozen data' do
        executor.filter(:erb)

        expect(snapshot_repo.get(rep, :last)).to be_frozen
      end
    end

    context 'normal flow with binary rep' do
      subject { executor.filter(:whatever) }

      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('foo.dat')) }

      before do
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        File.write(content.filename, 'Foo Data')

        filter_class = Class.new(::Nanoc::Filter) do
          type :binary

          def run(filename, _params = {})
            File.write(output_filename, "Compiled data for #{filename}")
          end
        end

        expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }

        snapshot_repo.set(rep, :last, content)
      end

      it 'does not set :pre on rep' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post on rep' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last on rep' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last) }
          .from(some_binary_content('Foo Data'))
          .to(some_binary_content(/\ACompiled data for \/.*\/foo.dat\z/))
      end

      it 'does not set :pre in repo' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last in repo' do
        expect { subject }
          .to change { File.read(snapshot_repo.get(rep, :last).filename) }
          .from('Foo Data')
          .to(/\ACompiled data for \/.*\/foo.dat\z/)
      end

      it 'returns frozen data' do
        executor.filter(:whatever)

        expect(snapshot_repo.get(rep, :last)).to be_frozen
      end
    end

    context 'normal flow with binary rep and binary-to-text filter' do
      subject { executor.filter(:whatever) }

      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('foo.dat')) }

      before do
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        File.write(content.filename, 'Foo Data')

        filter_class = Class.new(::Nanoc::Filter) do
          type binary: :text

          def run(filename, _params = {})
            "Compiled data for #{filename}"
          end
        end

        expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }

        snapshot_repo.set(rep, :last, content)
      end

      it 'does not set :pre on rep' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post on rep' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last on rep' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last) }
          .from(some_binary_content('Foo Data'))
          .to(some_textual_content(/\ACompiled data for \/.*\/foo.dat\z/))
      end

      it 'does not set :pre in repo' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last in repo' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last) }
          .from(some_binary_content('Foo Data'))
          .to(some_textual_content(/\ACompiled data for \/.*\/foo.dat\z/))
      end
    end

    context 'normal flow with textual rep and text-to-binary filter' do
      subject { executor.filter(:whatever) }

      before do
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        filter_class = Class.new(::Nanoc::Filter) do
          type text: :binary

          def run(content, _params = {})
            File.write(output_filename, "Binary #{content}")
          end
        end

        expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }

        snapshot_repo.set(rep, :last, content)
      end

      it 'does not set :pre on rep' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post on rep' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last on rep' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last) }
          .from(some_textual_content('<%= "Donkey" %> Power'))
          .to(some_binary_content('Binary <%= "Donkey" %> Power'))
      end

      it 'does not set :pre in repo' do
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :pre) }
      end

      it 'does not set :post in repo' do
        expect(snapshot_repo.get(rep, :post)).to be_nil
        expect { subject }.not_to change { snapshot_repo.get(rep, :post) }
      end

      it 'updates :last in repo' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last) }
          .from(some_textual_content('<%= "Donkey" %> Power'))
          .to(some_binary_content('Binary <%= "Donkey" %> Power'))
      end
    end

    context 'non-existant filter' do
      it 'raises' do
        expect { executor.filter(:ajlsdfjklaskldfj) }
          .to raise_error(Nanoc::Int::Errors::UnknownFilter)
      end
    end

    context 'non-binary rep, binary-to-something filter' do
      before do
        filter_class = Class.new(::Nanoc::Filter) do
          type :binary

          def run(_content, _params = {}); end
        end

        expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }

        snapshot_repo.set(rep, :last, content)
      end

      it 'raises' do
        expect { executor.filter(:whatever) }
          .to raise_error(Nanoc::Int::Errors::CannotUseBinaryFilter)
      end
    end

    context 'binary rep, text-to-something filter' do
      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('foo.md')) }

      before do
        snapshot_repo.set(rep, :last, content)
      end

      it 'raises' do
        expect { executor.filter(:erb) }
          .to raise_error(Nanoc::Int::Errors::CannotUseTextualFilter)
      end
    end

    context 'binary filter that does not write anything' do
      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('foo.dat')) }

      before do
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :whatever)
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :whatever)

        File.write(content.filename, 'Foo Data')

        filter_class = Class.new(::Nanoc::Filter) do
          type :binary

          def run(_filename, _params = {}); end
        end

        snapshot_repo.set(rep, :last, content)

        expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }
      end

      example do
        expect { executor.filter(:whatever) }
          .to raise_error(Nanoc::Int::Executor::OutputNotWrittenError)
      end
    end

    context 'content is frozen' do
      before do
        snapshot_repo.set(rep, :last, item.content)
      end

      let(:item) do
        Nanoc::Int::Item.new('foo bar', {}, '/foo.md').tap(&:freeze)
      end

      let(:filter_that_modifies_content) do
        Class.new(::Nanoc::Filter) do
          def run(content, _params = {})
            content.gsub!('foo', 'moo')
            content
          end
        end
      end

      let(:filter_that_modifies_params) do
        Class.new(::Nanoc::Filter) do
          def run(_content, params = {})
            params[:foo] = 'bar'
            'asdf'
          end
        end
      end

      it 'errors when attempting to modify content' do
        expect(Nanoc::Filter).to receive(:named).with(:whatever).and_return(filter_that_modifies_content)
        expect { executor.filter(:whatever) }.to raise_frozen_error
      end

      it 'receives frozen filter args' do
        expect(Nanoc::Filter).to receive(:named).with(:whatever).and_return(filter_that_modifies_params)
        expect { executor.filter(:whatever) }.to raise_frozen_error
      end
    end
  end

  describe '#layout' do
    let(:site) { double(:site, config: config, layouts: layouts) }

    let(:config) do
      {
        string_pattern_type: 'glob',
      }
    end

    let(:layout) do
      Nanoc::Int::Layout.new(layout_content, { bug: 'Gum Emperor' }, '/default.erb')
    end

    let(:layouts) { [layout] }

    let(:layout_content) { 'head <%= @foo %> foot' }

    let(:assigns) do
      { foo: 'hallo' }
    end

    let(:view_context) do
      Nanoc::ViewContext.new(
        reps: double(:reps),
        items: double(:items),
        dependency_tracker: dependency_tracker,
        compilation_context: double(:compilation_context),
        snapshot_repo: snapshot_repo,
      )
    end

    let(:action_sequence) do
      Nanoc::Int::ActionSequence.build(rep) do |b|
        b.add_filter(:erb, {})
      end
    end

    before do
      rep.snapshot_defs = [Nanoc::Int::SnapshotDef.new(:pre, binary: false)]

      snapshot_repo.set(rep, :last, content)

      allow(compilation_context).to receive(:site) { site }
      allow(compilation_context).to receive(:assigns_for).with(rep, dependency_tracker) { assigns }
      allow(compilation_context).to receive(:create_view_context).with(dependency_tracker).and_return(view_context)

      allow(action_provider).to receive(:action_sequence_for).with(layout).and_return(action_sequence)
    end

    subject { executor.layout('/default.*') }

    context 'accessing layout attributes' do
      let(:layout_content) { 'head <%= @layout[:bug] %> foot' }

      it 'exposes @layout as view' do
        allow(dependency_tracker).to receive(:enter)
          .with(layout, raw_content: true, attributes: false, compiled_content: false, path: false)
        allow(dependency_tracker).to receive(:enter)
          .with(layout, raw_content: false, attributes: [:bug], compiled_content: false, path: false)
        allow(dependency_tracker).to receive(:exit)
        subject
        expect(snapshot_repo.get(rep, :last).string).to eq('head Gum Emperor foot')
      end
    end

    context 'normal flow' do
      it 'updates :last on rep' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last) }
          .from(some_textual_content('Donkey Power'))
          .to(some_textual_content('head hallo foot'))
      end

      it 'updates :last in repo' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :last) }
          .from(some_textual_content('Donkey Power'))
          .to(some_textual_content('head hallo foot'))
      end

      it 'sets frozen content' do
        subject
        expect(snapshot_repo.get(rep, :last)).to be_frozen
        expect(snapshot_repo.get(rep, :pre)).to be_frozen
      end

      it 'does not create pre snapshot' do
        # a #layout is followed by a #snapshot(:pre, …)
        expect(snapshot_repo.get(rep, :pre)).to be_nil
        subject
        expect(snapshot_repo.get(rep, :pre)).to be_nil
      end

      it 'sends notifications' do
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_started, rep, :erb).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:filtering_ended, rep, :erb).ordered

        subject
      end

      context 'compiled_content reference in layout' do
        let(:layout_content) { 'head <%= @item_rep.compiled_content(snapshot: :pre) %> foot' }

        let(:assigns) do
          { item_rep: Nanoc::ItemRepView.new(rep, view_context) }
        end

        before do
          executor.snapshot(:pre)
        end

        it 'updates :last on rep' do
          expect { subject }
            .to change { snapshot_repo.get(rep, :last) }
            .from(some_textual_content('Donkey Power'))
            .to(some_textual_content('head Donkey Power foot'))
        end

        it 'updates :last in repo' do
          expect { subject }
            .to change { snapshot_repo.get(rep, :last) }
            .from(some_textual_content('Donkey Power'))
            .to(some_textual_content('head Donkey Power foot'))
        end
      end

      context 'content with layout reference' do
        let(:layout_content) { 'head <%= @layout.identifier %> foot' }

        it 'updates :last on rep' do
          expect { subject }
            .to change { snapshot_repo.get(rep, :last) }
            .from(some_textual_content('Donkey Power'))
            .to(some_textual_content('head /default.erb foot'))
        end

        it 'updates :last in repo' do
          expect { subject }
            .to change { snapshot_repo.get(rep, :last) }
            .from(some_textual_content('Donkey Power'))
            .to(some_textual_content('head /default.erb foot'))
        end
      end
    end

    context 'no layout found' do
      let(:layouts) do
        [Nanoc::Int::Layout.new('head <%= @foo %> foot', {}, '/other.erb')]
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::UnknownLayout)
      end
    end

    context 'no filter specified' do
      let(:action_sequence) do
        Nanoc::Int::ActionSequence.new(rep)
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::UndefinedFilterForLayout)
      end
    end

    context 'binary item' do
      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('donkey.md')) }

      it 'raises' do
        expect { subject }.to raise_error(
          Nanoc::Int::Errors::CannotLayoutBinaryItem,
          'The “/index.md” item (rep “donkey”) cannot be laid out because it is a binary item. If you are getting this error for an item that should be textual instead of binary, make sure that its extension is included in the text_extensions array in the site configuration.',
        )
      end
    end

    it 'receives frozen filter args' do
      filter_class = Class.new(::Nanoc::Filter) do
        def run(_content, params = {})
          params[:foo] = 'bar'
          'asdf'
        end
      end

      expect(Nanoc::Filter).to receive(:named).with(:erb) { filter_class }

      expect { subject }.to raise_frozen_error
    end
  end

  describe '#snapshot' do
    subject { executor.snapshot(:something) }

    before do
      snapshot_repo.set(rep, :last, content)

      File.write('donkey.dat', 'binary donkey')
    end

    context 'binary content' do
      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('donkey.dat')) }

      it 'creates snapshots on rep' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :something) }
          .from(nil)
          .to(some_binary_content('binary donkey'))
      end

      it 'creates snapshots in repo' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :something) }
          .from(nil)
          .to(some_binary_content('binary donkey'))
      end
    end

    context 'textual content' do
      let(:content) { Nanoc::Int::TextualContent.new('Donkey Power') }

      it 'creates snapshots on rep' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :something) }
          .from(nil)
          .to(some_textual_content('Donkey Power'))
      end

      it 'creates snapshots in repo' do
        expect { subject }
          .to change { snapshot_repo.get(rep, :something) }
          .from(nil)
          .to(some_textual_content('Donkey Power'))
      end
    end

    context 'final snapshot' do
      let(:content) { Nanoc::Int::TextualContent.new('Donkey Power') }

      context 'raw path' do
        before do
          rep.raw_paths = { something: ['output/donkey.md'] }
        end

        it 'does not write' do
          executor.snapshot(:something)

          expect(File.file?('output/donkey.md')).not_to be
        end
      end

      context 'no raw path' do
        it 'does not write' do
          executor.snapshot(:something)

          expect(File.file?('output/donkey.md')).to eq(false)
        end
      end
    end
  end

  describe '#find_layout' do
    let(:site) { double(:site, config: config, layouts: layouts) }

    let(:config) { {} }

    before do
      allow(compilation_context).to receive(:site) { site }
    end

    subject { executor.find_layout(arg) }

    context 'layout with cleaned identifier exists' do
      let(:arg) { '/default' }

      let(:layouts) do
        [Nanoc::Int::Layout.new('head <%= @foo %> foot', {}, '/default/')]
      end

      it { is_expected.to eq(layouts[0]) }
    end

    context 'no layout with cleaned identifier exists' do
      let(:layouts) do
        [Nanoc::Int::Layout.new('head <%= @foo %> foot', {}, '/default.erb')]
      end

      context 'globs' do
        let(:config) { { string_pattern_type: 'glob' } }

        let(:arg) { '/default.*' }

        it { is_expected.to eq(layouts[0]) }
      end

      context 'no globs' do
        let(:config) { { string_pattern_type: 'legacy' } }

        let(:arg) { '/default.*' }

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::UnknownLayout)
        end
      end
    end
  end
end
