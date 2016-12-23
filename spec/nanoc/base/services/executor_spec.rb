describe Nanoc::Int::Executor do
  let(:executor) { described_class.new(compiler, dependency_tracker) }

  let(:compiler) { Nanoc::Int::Compiler.allocate }
  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }

  describe '#filter' do
    let(:assigns) { {} }

    let(:content) { Nanoc::Int::TextualContent.new('<%= "Donkey" %> Power') }

    let(:item) { Nanoc::Int::Item.new(content, {}, '/') }

    let(:rep) { Nanoc::Int::ItemRep.new(item, :donkey) }

    before do
      allow(compiler).to receive(:assigns_for) { assigns }
    end

    context 'normal flow with textual rep' do
      before do
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_started, rep, :erb)
        expect(Nanoc::Int::NotificationCenter)
          .to receive(:post).with(:filtering_ended, rep, :erb)
      end

      example do
        executor.filter(rep, :erb)

        expect(rep.snapshot_contents[:last].string).to eq('Donkey Power')
        expect(rep.snapshot_contents[:pre].string).to eq('Donkey Power')
        expect(rep.snapshot_contents[:post]).to be_nil
      end

      it 'returns frozen data' do
        executor.filter(rep, :erb)

        expect(rep.snapshot_contents[:last]).to be_frozen
        expect(rep.snapshot_contents[:pre]).to be_frozen
      end
    end

    context 'normal flow with binary rep' do
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
      end

      example do
        executor.filter(rep, :whatever)

        expect(File.read(rep.snapshot_contents[:last].filename))
          .to match(/\ACompiled data for \/.*\/foo.dat\z/)
        expect(rep.snapshot_contents[:pre]).to be_nil
        expect(rep.snapshot_contents[:post]).to be_nil
      end

      it 'returns frozen data' do
        executor.filter(rep, :whatever)

        expect(rep.snapshot_contents[:last]).to be_frozen
      end
    end

    context 'normal flow with binary rep and binary-to-text filter' do
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
      end

      example do
        executor.filter(rep, :whatever)

        expect(rep.snapshot_contents[:last].string).to match(/\ACompiled data for \/.*\/foo.dat\z/)
        expect(rep.snapshot_contents[:pre].string).to match(/\ACompiled data for \/.*\/foo.dat\z/)
        expect(rep.snapshot_contents[:post]).to be_nil
      end
    end

    context 'normal flow with textual rep and text-to-binary filter' do
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
      end

      example do
        executor.filter(rep, :whatever)

        expect(File.read(rep.snapshot_contents[:last].filename))
          .to eq('Binary <%= "Donkey" %> Power')
        expect(rep.snapshot_contents[:pre]).to be_nil
        expect(rep.snapshot_contents[:post]).to be_nil
      end
    end

    context 'non-existant filter' do
      it 'raises' do
        expect { executor.filter(rep, :ajlsdfjklaskldfj) }
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
      end

      it 'raises' do
        expect { executor.filter(rep, :whatever) }
          .to raise_error(Nanoc::Int::Errors::CannotUseBinaryFilter)
      end
    end

    context 'binary rep, text-to-something filter' do
      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('foo.md')) }

      it 'raises' do
        expect { executor.filter(rep, :erb) }
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

        expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }
      end

      example do
        expect { executor.filter(rep, :whatever) }
          .to raise_error(Nanoc::Int::Executor::OutputNotWrittenError)
      end
    end

    it 'receives frozen content argument' do
      filter_class = Class.new(::Nanoc::Filter) do
        def run(content, _params = {})
          content.gsub!('foo', 'moo')
          content
        end
      end

      item = Nanoc::Int::Item.new('foo bar', {}, '/foo/')
      item.freeze
      expect(item.content).to be_frozen
      expect(item.content.string).to be_frozen
      rep = Nanoc::Int::ItemRep.new(item, :default)

      expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }

      expect { executor.filter(rep, :whatever) }.to raise_frozen_error
    end

    it 'receives frozen filter args' do
      filter_class = Class.new(::Nanoc::Filter) do
        def run(_content, params = {})
          params[:foo] = 'bar'
          'asdf'
        end
      end

      item = Nanoc::Int::Item.new('foo bar', {}, '/foo/')
      rep = Nanoc::Int::ItemRep.new(item, :default)

      expect(Nanoc::Filter).to receive(:named).with(:whatever) { filter_class }

      expect { executor.filter(rep, :whatever) }.to raise_frozen_error
    end
  end

  describe '#layout' do
    let(:item) { Nanoc::Int::Item.new(content, {}, '/index.md') }

    let(:rep) { Nanoc::Int::ItemRep.new(item, :donkey) }

    let(:content) { Nanoc::Int::TextualContent.new('Donkey Power').tap(&:freeze) }

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
        compiler: double(:compiler),
      )
    end

    let(:rule_memory) do
      Nanoc::Int::RuleMemory.new(rep).tap do |mem|
        mem.add_filter(:erb, {})
      end
    end

    let(:action_provider) { double(:action_provider) }

    before do
      allow(compiler).to receive(:site) { site }
      allow(compiler).to receive(:action_provider) { action_provider }
      allow(compiler).to receive(:assigns_for).with(rep, dependency_tracker) { assigns }
      allow(compiler).to receive(:create_view_context).with(dependency_tracker).and_return(view_context)
      allow(action_provider).to receive(:memory_for).with(layout).and_return(rule_memory)
    end

    subject { executor.layout(rep, '/default.*') }

    context 'accessing layout attributes' do
      let(:layout_content) { 'head <%= @layout[:bug] %> foot' }

      it 'exposes @layout as view' do
        allow(dependency_tracker).to receive(:enter)
          .with(layout, raw_content: true, attributes: false, compiled_content: false, path: false)
        allow(dependency_tracker).to receive(:enter)
          .with(layout, raw_content: false, attributes: true, compiled_content: false, path: false)
        allow(dependency_tracker).to receive(:exit)
        subject
        expect(rep.snapshot_contents[:last].string).to eq('head Gum Emperor foot')
      end
    end

    context 'normal flow' do
      it 'updates last content' do
        subject
        expect(rep.snapshot_contents[:last].string).to eq('head hallo foot')
      end

      it 'sets frozen content' do
        subject
        expect(rep.snapshot_contents[:last]).to be_frozen
        expect(rep.snapshot_contents[:pre]).to be_frozen
      end

      it 'creates pre snapshot' do
        expect(rep.snapshot_contents[:pre]).to be_nil
        subject
        expect(rep.snapshot_contents[:pre].string).to eq('Donkey Power')
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

        it 'can contain compiled_content reference' do
          subject
          expect(rep.snapshot_contents[:last].string).to eq('head Donkey Power foot')
        end
      end

      context 'content with layout reference' do
        let(:layout_content) { 'head <%= @layout.identifier %> foot' }

        it 'includes layout in assigns' do
          subject
          expect(rep.snapshot_contents[:last].string).to eq('head /default.erb foot')
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
      let(:rule_memory) do
        Nanoc::Int::RuleMemory.new(rep)
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::UndefinedFilterForLayout)
      end
    end

    context 'binary item' do
      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('donkey.md')) }

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::CannotLayoutBinaryItem)
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
    let(:item) { Nanoc::Int::Item.new(content, {}, '/') }

    let(:rep) { Nanoc::Int::ItemRep.new(item, :donkey) }

    context 'binary content' do
      let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('donkey.dat')) }

      it 'does not create snapshots' do
        executor.snapshot(rep, :something)

        expect(rep.snapshot_contents[:something]).to be_nil
      end
    end

    context 'textual content' do
      let(:content) { Nanoc::Int::TextualContent.new('Donkey Power') }

      it 'creates a snapshot' do
        executor.snapshot(rep, :something)

        expect(rep.snapshot_contents[:something].string).to eq('Donkey Power')
      end
    end

    context 'final snapshot' do
      let(:content) { Nanoc::Int::TextualContent.new('Donkey Power') }

      context 'snapshot is :pre' do
        it 'create a new snapshot def' do
          executor.snapshot(rep, :pre)

          expect(rep.snapshot_defs.size).to eq(1)
          expect(rep.snapshot_defs[0].name).to eq(:pre)
          expect(rep.snapshot_defs[0]).to be_final
        end
      end

      context 'raw path' do
        before do
          rep.raw_paths = { something: 'output/donkey.md' }
        end

        it 'writes' do
          executor.snapshot(rep, :something)

          expect(File.read('output/donkey.md')).to eq('Donkey Power')
        end
      end

      context 'no raw path' do
        it 'does not write' do
          executor.snapshot(rep, :something)

          expect(File.file?('output/donkey.md')).to eq(false)
        end
      end
    end
  end

  describe '#find_layout' do
    let(:site) { double(:site, config: config, layouts: layouts) }

    let(:config) { {} }

    before do
      allow(compiler).to receive(:site) { site }
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
