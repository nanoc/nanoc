# frozen_string_literal: true

describe Nanoc::Int::ConfigLoader do
  let(:loader) { described_class.new }

  describe '#new_from_cwd' do
    subject { loader.new_from_cwd }

    context 'no config file present' do
      it 'errors' do
        expect { subject }.to raise_error(
          Nanoc::Int::ConfigLoader::NoConfigFileFoundError,
        )
      end
    end

    context 'config file present' do
      before do
        File.write('nanoc.yaml', YAML.dump(foo: 'bar'))
      end

      it 'returns a configuration' do
        expect(subject).to be_a(Nanoc::Int::Configuration)
      end

      it 'has the defaults' do
        expect(subject[:output_dir]).to eq('output')
      end

      it 'has the custom option' do
        expect(subject[:foo]).to eq('bar')
      end
    end

    context 'config file and parent present' do
      before do
        File.write('nanoc.yaml', YAML.dump(parent_config_file: 'parent.yaml'))
        File.write('parent.yaml', YAML.dump(foo: 'bar'))
      end

      it 'returns the configuration' do
        expect(subject).to be_a(Nanoc::Int::Configuration)
      end

      it 'has the defaults' do
        expect(subject[:output_dir]).to eq('output')
      end

      it 'has the custom option' do
        expect(subject[:foo]).to eq('bar')
      end

      it 'does not include parent config option' do
        expect(subject[:parent_config_file]).to be_nil
      end
    end

    context 'config file present, environment defined' do
      let(:active_env_name) { 'default' }

      let(:config) do
        {
          foo: 'bar',
          tofoo: 'bar',
          environments: {
            test: { foo: 'test-bar' },
            default: { foo: 'default-bar' },
          },
        }
      end

      before do
        File.write('nanoc.yaml', YAML.dump(config))
      end

      before do
        expect(ENV).to receive(:fetch).with('NANOC_ENV', 'default').and_return(active_env_name)
      end

      it 'returns the configuration' do
        expect(subject).to be_a(Nanoc::Int::Configuration)
      end

      it 'has option defined not within environments' do
        expect(subject[:tofoo]).to eq('bar')
      end

      context 'current env is test' do
        let(:active_env_name) { 'test' }

        it 'has the test environment custom option' do
          expect(subject[:foo]).to eq('test-bar')
        end
      end

      it 'has the default environment custom option' do
        expect(subject[:foo]).to eq('default-bar')
      end
    end
  end

  describe '.cwd_is_nanoc_site? + .config_filename_for_cwd' do
    context 'no config files' do
      it 'is not considered a nanoc site dir' do
        expect(described_class.cwd_is_nanoc_site?).to eq(false)
        expect(described_class.config_filename_for_cwd).to be_nil
      end
    end

    context 'nanoc.yaml config file' do
      before do
        File.write('nanoc.yaml', 'stuff')
      end

      it 'is considered a nanoc site dir' do
        expect(described_class.cwd_is_nanoc_site?).to eq(true)
        expect(described_class.config_filename_for_cwd).to eq(File.expand_path('nanoc.yaml'))
      end
    end

    context 'config.yaml config file' do
      before do
        File.write('config.yaml', 'stuff')
      end

      it 'is considered a nanoc site dir' do
        expect(described_class.cwd_is_nanoc_site?).to eq(true)
        expect(described_class.config_filename_for_cwd).to eq(File.expand_path('config.yaml'))
      end
    end
  end

  describe '#apply_parent_config' do
    subject { loader.apply_parent_config(config, processed_paths) }

    let(:config) { Nanoc::Int::Configuration.new(hash: { foo: 'bar' }) }

    let(:processed_paths) { ['nanoc.yaml'] }

    context 'no parent_config_file' do
      it 'returns self' do
        expect(subject).to eq(config)
      end
    end

    context 'parent config file is set' do
      let(:config) do
        Nanoc::Int::Configuration.new(hash: { parent_config_file: 'foo.yaml', foo: 'bar' })
      end

      context 'parent config file is not present' do
        it 'errors' do
          expect { subject }.to raise_error(
            Nanoc::Int::ConfigLoader::NoParentConfigFileFoundError,
          )
        end
      end

      context 'parent config file is present' do
        context 'parent-child cycle' do
          before do
            File.write('foo.yaml', 'parent_config_file: bar.yaml')
            File.write('bar.yaml', 'parent_config_file: foo.yaml')
          end

          it 'errors' do
            expect { subject }.to raise_error(
              Nanoc::Int::ConfigLoader::CyclicalConfigFileError,
            )
          end
        end

        context 'self parent-child cycle' do
          before do
            File.write('foo.yaml', 'parent_config_file: foo.yaml')
          end

          it 'errors' do
            expect { subject }.to raise_error(
              Nanoc::Int::ConfigLoader::CyclicalConfigFileError,
            )
          end
        end

        context 'no parent-child cycle' do
          before do
            File.write('foo.yaml', 'animal: giraffe')
          end

          it 'returns a configuration' do
            expect(subject).to be_a(Nanoc::Int::Configuration)
          end

          it 'has no defaults (added in #new_from_cwd only)' do
            expect(subject[:output_dir]).to be_nil
          end

          it 'inherits options from parent' do
            expect(subject[:animal]).to eq('giraffe')
          end

          it 'takes options from child' do
            expect(subject[:foo]).to eq('bar')
          end

          it 'does not include parent config option' do
            expect(subject[:parent_config_file]).to be_nil
          end
        end

        context 'long parent chain' do
          before do
            File.write('foo.yaml', "parrots: 43\nparent_config_file: bar.yaml\n")
            File.write('bar.yaml', "day_one: lasers\nslugs: false\n")
          end

          it 'returns a configuration' do
            expect(subject).to be_a(Nanoc::Int::Configuration)
          end

          it 'has no defaults (added in #new_from_cwd only)' do
            expect(subject[:output_dir]).to be_nil
          end

          it 'inherits options from grandparent' do
            expect(subject[:day_one]).to eq('lasers')
            expect(subject[:slugs]).to eq(false)
          end

          it 'inherits options from parent' do
            expect(subject[:parrots]).to eq(43)
          end

          it 'takes options from child' do
            expect(subject[:foo]).to eq('bar')
          end

          it 'does not include parent config option' do
            expect(subject[:parent_config_file]).to be_nil
          end
        end
      end
    end
  end
end
