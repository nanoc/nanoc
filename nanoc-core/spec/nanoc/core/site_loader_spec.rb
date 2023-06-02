# frozen_string_literal: true

describe Nanoc::Core::SiteLoader do
  let(:loader) { described_class.new }

  Class.new(Nanoc::Core::DataSource) do
    identifier :iyf5eeqefhzyu6vdda7cibfbhou1mnm7

    def items
      [Nanoc::Core::Item.new('I am Denis!', {}, '/about.md')]
    end

    def layouts
      [Nanoc::Core::Layout.new('<html><%= yield %></html>', {}, '/page.erb')]
    end
  end

  describe '#new_from_cwd' do
    subject { loader.new_from_cwd }

    context 'no config file' do
      it 'errors' do
        expect { subject }.to raise_error(
          Nanoc::Core::ConfigLoader::NoConfigFileFoundError,
        )
      end
    end

    shared_examples 'a directory with a config file' do
      it 'has the default configuration' do
        expect(subject.config).to be_a(Nanoc::Core::Configuration)
        expect(subject.config[:index_filenames]).to eq(['index.html'])
        expect(subject.config[:foo]).to eq('bar')
      end

      it 'has no code snippets' do
        expect(subject.code_snippets).to be_empty
      end

      it 'has an item' do
        expect(subject.items.size).to eq(1)
        expect(subject.items.object_with_identifier('/about.md').content)
          .to be_a(Nanoc::Core::TextualContent)
        expect(subject.items.object_with_identifier('/about.md').content.string)
          .to eq('I am Denis!')
        expect(subject.items.object_with_identifier('/about.md').identifier.to_s)
          .to eq('/about.md')
      end

      it 'has a layout' do
        expect(subject.layouts.size).to eq(1)
        expect(subject.layouts.object_with_identifier('/page.erb').content)
          .to be_a(Nanoc::Core::TextualContent)
        expect(subject.layouts.object_with_identifier('/page.erb').content.string)
          .to eq('<html><%= yield %></html>')
        expect(subject.layouts.object_with_identifier('/page.erb').identifier.to_s)
          .to eq('/page.erb')
      end

      context 'some items, layouts, and code snippets' do
        before do
          FileUtils.mkdir_p('lib')
          File.write('lib/foo.rb', '$spirit_animal = :donkey')
        end

        it 'has a code snippet' do
          expect(subject.code_snippets.size).to eq(1)
          expect(subject.code_snippets[0].data).to eq('$spirit_animal = :donkey')
        end
      end
    end

    context 'nanoc.yaml config file' do
      before do
        File.write('nanoc.yaml', <<~EOS)
          foo: bar
          data_sources:
            - type: iyf5eeqefhzyu6vdda7cibfbhou1mnm7
        EOS
      end

      it_behaves_like 'a directory with a config file'
    end

    context 'config.yaml config file' do
      before do
        File.write('config.yaml', <<~EOS)
          foo: bar
          data_sources:
            - type: iyf5eeqefhzyu6vdda7cibfbhou1mnm7
        EOS
      end

      it_behaves_like 'a directory with a config file'
    end

    context 'configuration has non-existant data source' do
      before do
        File.write('nanoc.yaml', <<-EOS.gsub(/^ {10}/, ''))
          data_sources:
            - type: eenvaleed
        EOS
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Nanoc::Core::Errors::UnknownDataSource)
      end
    end

    context 'environments defined' do
      before do
        File.write('nanoc.yaml', <<-EOS.gsub(/^ {10}/, ''))
          animal: donkey
          data_sources:
            - type: iyf5eeqefhzyu6vdda7cibfbhou1mnm7
          environments:
            staging:
              animal: giraffe
        EOS

        expect(ENV).to receive(:fetch).with('NANOC_ENV', 'default').and_return('staging')
      end

      it 'does not load environment' do
        expect(subject.config[:animal]).to eq('giraffe')
      end
    end

    context 'code snippet with data source implementation' do
      before do
        FileUtils.mkdir_p('lib')
        File.write('lib/foo_data_source.rb', <<-EOS.gsub(/^ {10}/, ''))
          class FooDataSource < Nanoc::Core::DataSource
            identifier :site_loader_spec_sample

            def items
              [
                Nanoc::Core::Item.new(
                  'Generated content!',
                  { generated: true },
                  '/generated.txt',
                )
              ]
            end
          end
        EOS

        File.write('nanoc.yaml', <<-EOS.gsub(/^ {10}/, ''))
          data_sources:
            - type: site_loader_spec_sample
        EOS
      end

      it 'loads code snippets before items/layouts' do
        expect(subject.items.size).to eq(1)
        expect(subject.items.object_with_identifier('/generated.txt').content)
          .to be_a(Nanoc::Core::TextualContent)
        expect(subject.items.object_with_identifier('/generated.txt').content.string)
          .to eq('Generated content!')
        expect(subject.items.object_with_identifier('/generated.txt').attributes)
          .to eq(generated: true)
        expect(subject.items.object_with_identifier('/generated.txt').identifier.to_s)
          .to eq('/generated.txt')
      end
    end
  end

  describe '#code_snippets_from_config' do
    subject { loader.send(:code_snippets_from_config, config) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

    before { FileUtils.mkdir_p('lib') }

    context 'no explicit encoding specified' do
      example do
        File.write('lib/asdf.rb', 'hi 🔥', encoding: 'utf-8')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('hi 🔥')
      end
    end

    context 'comment # encoding: x specified' do
      example do
        File.write('lib/asdf.rb', "# encoding: iso-8859-1\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end

    context 'comment # coding: x specified' do
      example do
        File.write('lib/asdf.rb', "# coding: iso-8859-1\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end

    context 'comment # -*- encoding: x -*- specified' do
      example do
        File.write('lib/asdf.rb', "# -*- encoding: iso-8859-1 -*-\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end

    context 'comment # -*- coding: x -*- specified' do
      example do
        File.write('lib/asdf.rb', "# -*- coding: iso-8859-1 -*-\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end
  end
end
