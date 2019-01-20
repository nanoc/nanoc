# frozen_string_literal: true

# Needs :view_class
shared_examples 'an identifiable collection view' do
  let(:view) { described_class.new(wrapped, view_context) }

  let(:view_context) do
    Nanoc::ViewContextForCompilation.new(
      reps: Nanoc::Int::ItemRepRepo.new,
      items: Nanoc::Int::ItemCollection.new(config),
      dependency_tracker: dependency_tracker,
      compilation_context: double(:__compilation_context),
      compiled_content_store: double(:__compiled_content_store),
    )
  end

  let(:dependency_tracker) do
    Nanoc::Int::DependencyTracker::Null.new
  end

  let(:config) do
    { string_pattern_type: 'glob' }
  end

  describe '#frozen?' do
    let(:wrapped) do
      collection_class.new(
        config,
        [
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/foo')),
          double(:identifiable, identifier: Nanoc::Core::Identifier.new('/bar')),
        ],
      )
    end

    subject { view.frozen? }

    context 'non-frozen collection' do
      it { is_expected.to be(false) }
    end

    context 'frozen collection' do
      before do
        wrapped.each { |o| expect(o).to receive(:freeze) }
        wrapped.freeze
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#_unwrap' do
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

    subject { view._unwrap }

    it { should equal(wrapped) }

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

    subject { view.size }

    it 'creates dependency' do
      expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: true)
      subject
    end

    it { should == 3 }
  end

  describe '#[]' do
    let(:page_object) do
      double(:identifiable, identifier: Nanoc::Core::Identifier.new('/page.erb'))
    end

    let(:home_object) do
      double(:identifiable, identifier: Nanoc::Core::Identifier.new('/home.erb'))
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

    subject { view[arg] }

    context 'no objects found' do
      let(:arg) { '/donkey.*' }
      it { is_expected.to equal(nil) }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: ['/donkey.*'])
        subject
      end
    end

    context 'string' do
      let(:arg) { '/home.erb' }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: ['/home.erb'])
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

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: ['/home.erb'])
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
        let(:config) { { string_pattern_type: 'legacy' } }

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
        expect(subject.size).to eql(2)
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
        expect(subject.size).to eql(2)
        about_css = subject.find { |iv| iv.identifier == '/about.css' }
        style_css = subject.find { |iv| iv.identifier == '/style.css' }
        expect(about_css.class).to equal(view_class)
        expect(style_css.class).to equal(view_class)
      end
    end

    context 'with block' do
      subject { view.find_all { |iv| iv.identifier =~ /css/ } }

      it 'creates dependency' do
        expect(dependency_tracker).to receive(:bounce).with(wrapped, raw_content: true)
        subject
      end

      it 'contains views' do
        expect(subject.size).to eql(2)
        about_css = subject.find { |iv| iv.identifier == '/about.css' }
        style_css = subject.find { |iv| iv.identifier == '/style.css' }
        expect(about_css.class).to equal(view_class)
        expect(style_css.class).to equal(view_class)
      end
    end
  end
end
