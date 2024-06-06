# frozen_string_literal: true

describe Nanoc::CLI::ErrorHandler, stdio: true do
  subject(:error_handler) { described_class.new }

  describe '#trivial?' do
    subject { error_handler.trivial?(error) }

    context 'LoadError of known gem' do
      let(:error) do
        raise LoadError, 'cannot load such file -- nokogiri'
      rescue LoadError => e
        return e
      end

      it { is_expected.to be(true) }
    end

    context 'LoadError of unknown gem' do
      let(:error) do
        raise LoadError, 'cannot load such file -- whatever'
      rescue LoadError => e
        return e
      end

      it { is_expected.to be(false) }
    end

    context 'random error' do
      let(:error) do
        raise 'stuff'
      rescue => e
        return e
      end

      it { is_expected.to be(false) }
    end

    context 'Errno::EADDRINUSE' do
      let(:error) do
        raise Errno::EADDRINUSE
      rescue => e
        return e
      end

      it { is_expected.to be(true) }
    end

    context 'TrivialError' do
      let(:error) do
        raise Nanoc::Core::TrivialError, 'oh just a tiny thing'
      rescue => e
        return e
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#handle_error' do
    subject { error_handler.handle_error(error, exit_on_error:) }

    let(:error) do
      raise 'Bewm'
    rescue => e
      return e
    end

    let(:exit_on_error) { false }

    describe 'exit behavior' do
      context 'exit on error' do
        let(:exit_on_error) { true }

        it 'exits on error' do
          expect { subject }.to raise_error(SystemExit)
        end
      end

      context 'no exit on error' do
        let(:exit_on_error) { false }

        it 'does not exit on error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'printing behavior' do
      context 'trivial error with no resolution' do
        let(:error) do
          raise Nanoc::Core::TrivialError, 'asdf'
        rescue => e
          return e
        end

        it 'prints summary' do
          expect { subject }.to output("\nError: asdf\n").to_stderr
        end
      end

      context 'LoadError' do
        let(:error) do
          raise LoadError, 'cannot load such file -- nokogiri'
        rescue LoadError => e
          return e
        end

        it 'prints summary' do
          expected_output = "\n" + <<~OUT
            Error: cannot load such file -- nokogiri

            1. Add `gem 'nokogiri'` to your Gemfile
            2. Run `bundle install`
            3. Re-run this command
          OUT
          expect { subject }.to output(expected_output).to_stderr
        end
      end

      context 'when error implements #full_message', stdio: true do
        let(:klass) do
          Class.new(StandardError) do
            def self.to_s
              'SubclassOfStandardError'
            end

            def full_message
              "okay so what I mean is that #{message}"
            end
          end
        end

        let(:error) do
          raise klass.new('it is broken')
        rescue => e
          return e
        end

        it 'prints error message followed by error detail' do
          subject

          expect($stderr.string).to match(
            %r{SubclassOfStandardError: it is broken.*okay so what I mean is that it is broken}m,
          )
        end
      end

      context 'non-trivial error' do
        # …
      end
    end
  end

  describe '#write_error_message' do
    subject { error_handler.send(:write_error_message, $stdout, error, verbose: true) }

    let(:error) do
      Nanoc::Core::Configuration.new(dir: '/oink', hash: { enable_output_diff: 'yeah' })
    rescue => e
      return e
    end

    example do
      expect { subject }.to output("\n===== MESSAGE:\n\nJsonSchema::AggregateError: \n  * #/enable_output_diff: For 'properties/enable_output_diff', \"yeah\" is not a boolean.\n").to_stdout
    end
  end

  describe 'GEM_NAMES' do
    example do
      requires = Nanoc::Core::Filter.all.flat_map(&:requires)
      described =
        Nanoc::CLI::ErrorHandler::GEM_NAMES.keys +
        ['erb', 'rdoc', 'nanoc/filters/sass/importer', 'nanoc/filters/sass/functions']

      missing = requires - described

      expect(missing).to be_empty
    end
  end

  describe '#handle_while' do
    it 'makes #exit bubble up a SystemExit' do
      expect do
        error_handler.handle_while(exit_on_error: false) do
          exit(0)
        end
      end.to raise_error(SystemExit)
    end
  end
end
