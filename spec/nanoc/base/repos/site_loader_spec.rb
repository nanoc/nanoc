# frozen_string_literal: true

describe Nanoc::Int::SiteLoader do
  let(:loader) { described_class.new }

  describe '#new_empty' do
    subject { loader.new_empty }

    it 'has the default configuration' do
      expect(subject.config).to be_a(Nanoc::Int::Configuration)
      expect(subject.config[:index_filenames]).to eq(['index.html'])
    end

    it 'has no code snippets' do
      expect(subject.code_snippets).to be_empty
    end

    it 'has no items' do
      expect(subject.items).to be_empty
    end

    it 'has no layouts' do
      expect(subject.layouts).to be_empty
    end
  end

  describe '#new_with_config' do
    subject { loader.new_with_config(arg) }

    let(:arg) { { foo: 'bar' } }

    it 'has a slightly modified configuration' do
      expect(subject.config).to be_a(Nanoc::Int::Configuration)
      expect(subject.config[:index_filenames]).to eq(['index.html'])
      expect(subject.config[:foo]).to eq('bar')
    end

    it 'has no code snippets' do
      expect(subject.code_snippets).to be_empty
    end

    it 'has no items' do
      expect(subject.items).to be_empty
    end

    it 'has no layouts' do
      expect(subject.layouts).to be_empty
    end
  end

  describe '#new_from_cwd' do
    subject { loader.new_from_cwd }

    context 'no config file' do
      it 'errors' do
        expect { subject }.to raise_error(
          Nanoc::Int::ConfigLoader::NoConfigFileFoundError,
        )
      end
    end

    shared_examples 'a directory with a config file' do
      it 'has the default configuration' do
        expect(subject.config).to be_a(Nanoc::Int::Configuration)
        expect(subject.config[:index_filenames]).to eq(['index.html'])
        expect(subject.config[:foo]).to eq('bar')
      end

      it 'has no code snippets' do
        expect(subject.code_snippets).to be_empty
      end

      it 'has no items' do
        expect(subject.items).to be_empty
      end

      it 'has no layouts' do
        expect(subject.layouts).to be_empty
      end

      context 'some items, layouts, and code snippets' do
        before do
          FileUtils.mkdir_p('lib')
          File.write('lib/foo.rb', '$spirit_animal = :donkey')

          FileUtils.mkdir_p('content')
          File.write('content/about.md', 'I am Denis!')

          FileUtils.mkdir_p('layouts')
          File.write('layouts/page.erb', '<html><%= yield %></html>')
        end

        it 'has a code snippet' do
          expect(subject.code_snippets.size).to eq(1)
          expect(subject.code_snippets[0].data).to eq('$spirit_animal = :donkey')
        end

        it 'has an item' do
          expect(subject.items.size).to eq(1)
          expect(subject.items['/about.md'].content).to be_a(Nanoc::Int::TextualContent)
          expect(subject.items['/about.md'].content.string).to eq('I am Denis!')
          expect(subject.items['/about.md'].attributes[:content_filename])
            .to eq('content/about.md')
          expect(subject.items['/about.md'].attributes[:extension])
            .to eq('md')
          expect(subject.items['/about.md'].attributes[:filename])
            .to eq('content/about.md')
          expect(subject.items['/about.md'].attributes[:meta_filename])
            .to be_nil
          expect(subject.items['/about.md'].attributes[:mtime])
            .to be > Time.now - 5
          expect(subject.items['/about.md'].identifier.to_s).to eq('/about.md')
        end

        it 'has a layout' do
          expect(subject.layouts.size).to eq(1)
          expect(subject.layouts['/page.erb'].content).to be_a(Nanoc::Int::TextualContent)
          expect(subject.layouts['/page.erb'].content.string).to eq('<html><%= yield %></html>')
          expect(subject.layouts['/page.erb'].attributes[:content_filename])
            .to eq('layouts/page.erb')
          expect(subject.layouts['/page.erb'].attributes[:extension])
            .to eq('erb')
          expect(subject.layouts['/page.erb'].attributes[:filename])
            .to eq('layouts/page.erb')
          expect(subject.layouts['/page.erb'].attributes[:meta_filename])
            .to be_nil
          expect(subject.layouts['/page.erb'].attributes[:mtime])
            .to be > Time.now - 5
          expect(subject.layouts['/page.erb'].identifier.to_s).to eq('/page.erb')
        end
      end
    end

    context 'nanoc.yaml config file' do
      before do
        File.write('nanoc.yaml', "---\nfoo: bar\n")
      end

      it_behaves_like 'a directory with a config file'
    end

    context 'config.yaml config file' do
      before do
        File.write('config.yaml', "---\nfoo: bar\n")
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
        expect { subject }.to raise_error(Nanoc::Int::Errors::UnknownDataSource)
      end
    end

    context 'environments defined' do
      before do
        File.write('nanoc.yaml', <<-EOS.gsub(/^ {10}/, ''))
          animal: donkey
          environments:
            staging:
              animal: giraffe
        EOS
      end

      before do
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
          class FooDataSource < Nanoc::DataSource
            identifier :site_loader_spec_sample

            def items
              [
                Nanoc::Int::Item.new(
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
        expect(subject.items['/generated.txt'].content).to be_a(Nanoc::Int::TextualContent)
        expect(subject.items['/generated.txt'].content.string).to eq('Generated content!')
        expect(subject.items['/generated.txt'].attributes).to eq(generated: true)
        expect(subject.items['/generated.txt'].identifier.to_s).to eq('/generated.txt')
      end
    end
  end

  describe '#code_snippets_from_config' do
    subject { loader.send(:code_snippets_from_config, config) }

    let(:config) { Nanoc::Int::Configuration.new.with_defaults }

    before { FileUtils.mkdir_p('lib') }

    context 'no explicit encoding specified' do
      example do
        File.write('lib/asdf.rb', 'hi 🔥', encoding: 'utf-8')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('hi 🔥')
      end
    end

    context '# encoding: x specified' do
      example do
        File.write('lib/asdf.rb', "# encoding: iso-8859-1\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end

    context '# coding: x specified' do
      example do
        File.write('lib/asdf.rb', "# coding: iso-8859-1\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end

    context '# -*- encoding: x -*- specified' do
      example do
        File.write('lib/asdf.rb', "# -*- encoding: iso-8859-1 -*-\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end

    context '# -*- coding: x -*- specified' do
      example do
        File.write('lib/asdf.rb', "# -*- coding: iso-8859-1 -*-\n\nBRØKEN", encoding: 'iso-8859-1')
        expect(subject.size).to eq(1)
        expect(subject.first.data).to eq('BRØKEN')
      end
    end
  end
end
