describe Nanoc::CLI::Commands::ShowData, stdio: true do
  describe '#print_item_dependencies' do
    subject { runner.send(:print_item_dependencies, items, dependency_store) }

    let(:runner) do
      described_class.new(options, arguments, command)
    end

    let(:options) { {} }
    let(:arguments) { [] }
    let(:command) { double(:command) }

    let(:items) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |ic|
        ic << item_about
        ic << item_dog
        ic << item_other
      end
    end

    let(:item_about) { Nanoc::Int::Item.new('About Me', {}, '/about.md') }
    let(:item_dog)   { Nanoc::Int::Item.new('About My Dog', {}, '/dog.md') }
    let(:item_other) { Nanoc::Int::Item.new('Raw Data', {}, '/other.dat') }

    let(:config) { Nanoc::Int::Configuration.new }

    let(:dependency_store) do
      Nanoc::Int::DependencyStore.new(objects)
    end

    let(:objects) do
      items.to_a + layouts.to_a
    end

    let(:layouts) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |ic|
      end
    end

    it 'prints a legend' do
      expect { subject }.to output(%r{Item dependencies =+\n\nLegend:}).to_stdout
    end

    context 'no dependencies' do
      it 'outputs no dependencies for /about.md' do
        expect { subject }.to output(%r{^item /about.md depends on:\n  \(nothing\)$}m).to_stdout
      end

      it 'outputs no dependencies for /dog.md' do
        expect { subject }.to output(%r{^item /dog.md depends on:\n  \(nothing\)$}m).to_stdout
      end

      it 'outputs no dependencies for /other.dat' do
        expect { subject }.to output(%r{^item /other.dat depends on:\n  \(nothing\)$}m).to_stdout
      end
    end

    context 'dependency (without props) from about to dog' do
      before do
        dependency_store.record_dependency(item_dog, item_about)
      end

      it 'outputs no dependencies for /about.md' do
        expect { subject }.to output(%r{^item /about.md depends on:\n  \(nothing\)$}m).to_stdout
      end

      it 'outputs dependencies for /dog.md' do
        expect { subject }.to output(%r{^item /dog.md depends on:\n  \[   item \] \(____\) /about.md$}m).to_stdout
      end

      it 'outputs no dependencies for /other.dat' do
        expect { subject }.to output(%r{^item /other.dat depends on:\n  \(nothing\)$}m).to_stdout
      end
    end

    context 'dependency (with raw_content prop) from about to dog' do
      before do
        dependency_store.record_dependency(item_dog, item_about, raw_content: true)
      end

      it 'outputs dependencies for /dog.md' do
        expect { subject }.to output(%r{^item /dog.md depends on:\n  \[   item \] \(r___\) /about.md$}m).to_stdout
      end
    end

    context 'dependency (with attributes prop) from about to dog' do
      before do
        dependency_store.record_dependency(item_dog, item_about, attributes: true)
      end

      it 'outputs dependencies for /dog.md' do
        expect { subject }.to output(%r{^item /dog.md depends on:\n  \[   item \] \(_a__\) /about.md$}m).to_stdout
      end
    end

    context 'dependency (with compiled_content prop) from about to dog' do
      before do
        dependency_store.record_dependency(item_dog, item_about, compiled_content: true)
      end

      it 'outputs dependencies for /dog.md' do
        expect { subject }.to output(%r{^item /dog.md depends on:\n  \[   item \] \(__c_\) /about.md$}m).to_stdout
      end
    end

    context 'dependency (with path prop) from about to dog' do
      before do
        dependency_store.record_dependency(item_dog, item_about, path: true)
      end

      it 'outputs dependencies for /dog.md' do
        expect { subject }.to output(%r{^item /dog.md depends on:\n  \[   item \] \(___p\) /about.md$}m).to_stdout
      end
    end

    context 'dependency (with multiple props) from about to dog' do
      before do
        dependency_store.record_dependency(item_dog, item_about, attributes: true, raw_content: true)
      end

      it 'outputs dependencies for /dog.md' do
        expect { subject }.to output(%r{^item /dog.md depends on:\n  \[   item \] \(ra__\) /about.md$}m).to_stdout
      end
    end
  end
end
