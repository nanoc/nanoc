# frozen_string_literal: true

# Needs :view_class
shared_examples 'an identifiable collection view' do
  let(:view) { described_class.new(wrapped, view_context) }

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

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:items) { Nanoc::Core::ItemCollection.new(config, []) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config, []) }

  let(:dependency_tracker) do
    Nanoc::Core::DependencyTracker::Null.new
  end

  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }
  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }

  let(:reps) { Nanoc::Core::ItemRepRepo.new }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  describe '#frozen?' do
    subject { view.frozen? }

    let(:wrapped) do
      collection_class.new(
        config,
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/foo')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/bar')),
        ],
      )
    end

    context 'non-frozen collection' do
      it { is_expected.to be(false) }
    end

    context 'frozen collection' do
      before do
        expect(wrapped).to all(receive(:freeze))
        wrapped.freeze
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#_unwrap' do
    subject { view._unwrap }

    let(:wrapped) do
      collection_class.new(
        config,
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/foo')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/bar')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/baz')),
        ],
      )
    end

    it { is_expected.to equal(wrapped) }

    it 'does not create dependency' do
      expect(dependency_tracker).not_to receive(:bounce)
      subject
    end
  end

  describe '#each' do
    let(:wrapped) do
      collection_class.new(
        config,
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/foo')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/bar')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/baz')),
        ],
      )
    end

    it 'creates dependency' do
      expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: true)
      view.each { |_i| }
    end

    it 'returns self' do
      expect(view.each { |_i| }).to equal(view)
    end

    it 'yields elements with the right context' do
      view.each { |v| expect(v._context).to equal(view_context) }
    end
  end

  describe '#size' do
    subject { view.size }

    let(:wrapped) do
      collection_class.new(
        config,
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/foo')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/bar')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/baz')),
        ],
      )
    end

    it 'creates dependency' do
      expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: true)
      subject
    end

    it { is_expected.to eq 3 }
  end

  describe '#[]' do
    subject { view[arg] }

    let(:page_object) do
      element_class.new('content', {}, Nanoc::Core::Identifier.new('/page.erb'))
    end

    let(:home_object) do
      element_class.new('content', {}, Nanoc::Core::Identifier.new('/home.erb'))
    end

    let(:wrapped) do
      collection_class.new(
        config,
        [
          page_object,
          home_object,
        ],
      )
    end

    context 'no objects found' do
      let(:arg) { '/donkey.*' }

      it { is_expected.to equal(nil) }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: ['/donkey.*'])
        subject
      end
    end

    context 'string, with exact match' do
      let(:arg) { '/home.erb' }

      it 'does not create dependency' do
        expect(dependency_tracker).not_to receive(:bounce)
        subject
      end

      it 'returns wrapped object' do
        expect(subject.class).to equal(view_class)
        expect(subject._unwrap).to equal(home_object)
      end

      it 'returns objects with right context' do
        expect(subject._context).to equal(view_context)
      end
    end

    context 'identifier' do
      let(:arg) { Nanoc::Core::Identifier.new('/home.erb') }

      it 'does not create dependency' do
        expect(dependency_tracker).not_to receive(:bounce)
        subject
      end

      it 'returns wrapped object' do
        expect(subject.class).to equal(view_class)
        expect(subject._unwrap).to equal(home_object)
      end
    end

    context 'glob' do
      let(:arg) { '/home.*' }

      context 'globs not enabled' do
        let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: { string_pattern_type: 'legacy' }).with_defaults }

        it 'creates dependency' do
          expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: ['/home.*'])
          subject
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'globs enabled' do
        it 'creates dependency' do
          expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: ['/home.*'])
          subject
        end

        it 'returns wrapped object' do
          expect(subject.class).to equal(view_class)
          expect(subject._unwrap).to equal(home_object)
        end
      end
    end

    context 'regex' do
      let(:arg) { %r{\A/home} }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: [%r{\A/home}])
        subject
      end

      it 'returns wrapped object' do
        expect(subject.class).to equal(view_class)
        expect(subject._unwrap).to equal(home_object)
      end
    end
  end

  describe '#find_all' do
    let(:wrapped) do
      collection_class.new(
        config,
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/about.css')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/about.md')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/style.css')),
        ],
      )
    end

    context 'with string' do
      subject { view.find_all('/*.css') }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: ['/*.css'])
        subject
      end

      it 'contains views' do
        expect(subject.size).to be(2)
        about_css = subject.find { |iv| iv.identifier == '/about.css' }
        style_css = subject.find { |iv| iv.identifier == '/style.css' }
        expect(about_css.class).to equal(view_class)
        expect(style_css.class).to equal(view_class)
      end
    end

    context 'with regex' do
      subject { view.find_all(%r{\.css\z}) }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: [%r{\.css\z}])
        subject
      end

      it 'contains views' do
        expect(subject.size).to be(2)
        about_css = subject.find { |iv| iv.identifier == '/about.css' }
        style_css = subject.find { |iv| iv.identifier == '/style.css' }
        expect(about_css.class).to equal(view_class)
        expect(style_css.class).to equal(view_class)
      end
    end

    context 'with block' do
      subject do
        view.find_all do |iv|
          expect(iv).to be_a(Nanoc::Core::View)
          iv.identifier =~ /css/
        end
      end

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: true)
        subject
      end

      it 'contains views' do
        expect(subject.size).to be(2)
        about_css = subject.find { |iv| iv.identifier == '/about.css' }
        style_css = subject.find { |iv| iv.identifier == '/style.css' }
        expect(about_css.class).to equal(view_class)
        expect(style_css.class).to equal(view_class)
      end
    end
  end

  describe '#where' do
    around do |ex|
      Nanoc::Core::Feature.enable('where') { ex.run }
    end

    let(:wrapped) do
      collection_class.new(
        config,
        [
          double(
            :identifiable,
            identifier: Nanoc::Core::Identifier.new('/bare.md'),
            attributes: {},
          ),
          double(
            :identifiable,
            identifier: Nanoc::Core::Identifier.new('/note.md'),
            attributes: { kind: 'note' },
          ),
          double(
            :identifiable,
            identifier: Nanoc::Core::Identifier.new('/note-2020.md'),
            attributes: { kind: 'note', year: 2020 },
          ),
          double(
            :identifiable,
            identifier: Nanoc::Core::Identifier.new('/note-2021.md'),
            attributes: { kind: 'note', year: 2021 },
          ),
        ],
      )
    end

    context 'with one attribute' do
      subject { view.where(kind: 'note') }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, attributes: { kind: 'note' })
        subject
      end

      it 'contains views' do
        expect(subject.size).to be(3)
        note = subject.find { |iv| iv.identifier == '/note.md' }
        note2020 = subject.find { |iv| iv.identifier == '/note-2020.md' }
        note2021 = subject.find { |iv| iv.identifier == '/note-2021.md' }
        expect(note.class).to equal(view_class)
        expect(note2020.class).to equal(view_class)
        expect(note2021.class).to equal(view_class)
      end
    end

    context 'with two attributes' do
      subject { view.where(kind: 'note', year: 2020) }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, attributes: { kind: 'note', year: 2020 })
        subject
      end

      it 'contains views' do
        expect(subject.size).to be(1)
        note2020 = subject.find { |iv| iv.identifier == '/note-2020.md' }
        expect(note2020.class).to equal(view_class)
      end
    end
  end
end
