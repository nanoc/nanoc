# frozen_string_literal: true

describe Nanoc::CLI::ErrorHandler, stdio: true do
  subject(:error_handler) { described_class.new }

  describe '#forwards_stack_trace?' do
    subject { error_handler.forwards_stack_trace? }

    context 'Ruby 2.4' do
      before do
        expect(error_handler).to receive(:ruby_version).and_return('2.4.2')
      end

      it { is_expected.to be(false) }
    end

    context 'Ruby 2.5' do
      before do
        expect(error_handler).to receive(:ruby_version).and_return('2.5.0')
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#trivial?' do
    subject { error_handler.trivial?(error) }

    context 'LoadError of known gem' do
      let(:error) do
        begin
          raise LoadError, 'cannot load such file -- nokogiri'
        rescue LoadError => e
          return e
        end
      end

      it { is_expected.to be(true) }
    end

    context 'LoadError of unknown gem' do
      let(:error) do
        begin
          raise LoadError, 'cannot load such file -- whatever'
        rescue LoadError => e
          return e
        end
      end

      it { is_expected.to be(false) }
    end

    context 'random error' do
      let(:error) do
        begin
          raise 'stuff'
        rescue => e
          return e
        end
      end

      it { is_expected.to be(false) }
    end

    context 'Errno::EADDRINUSE' do
      let(:error) do
        begin
          raise Errno::EADDRINUSE
        rescue => e
          return e
        end
      end

      it { is_expected.to be(true) }
    end

    context 'GenericTrivial' do
      let(:error) do
        begin
          raise Nanoc::Int::Errors::GenericTrivial, 'oh just a tiny thing'
        rescue => e
          return e
        end
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#handle_error' do
    subject { error_handler.handle_error(error, exit_on_error: exit_on_error) }

    let(:error) do
      begin
        raise 'Bewm'
      rescue => e
        return e
      end
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
          begin
            raise Nanoc::Int::Errors::GenericTrivial, 'asdf'
          rescue => e
            return e
          end
        end

        it 'prints summary' do
          expect { subject }.to output("\nError: asdf\n").to_stderr
        end
      end

      context 'LoadError' do
        let(:error) do
          begin
            raise LoadError, 'cannot load such file -- nokogiri'
          rescue LoadError => e
            return e
          end
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

      context 'non-trivial error' do
        # …
      end
    end
  end

  describe '#write_error_message' do
    subject { error_handler.send(:write_error_message, $stdout, error, verbose: true) }

    let(:error) do
      begin
        Nanoc::Core::Configuration.new(dir: '/oink', hash: { enable_output_diff: 'yeah' })
      rescue => e
        return e
      end
    end

    example do
      expect { subject }.to output("\n===== MESSAGE:\n\nJsonSchema::AggregateError: \n  * #/enable_output_diff: For 'properties/enable_output_diff', \"yeah\" is not a boolean.\n").to_stdout
    end
  end

  describe 'GEM_NAMES' do
    example do
      requires = Nanoc::Filter.all.flat_map(&:requires)
      described =
        Nanoc::CLI::ErrorHandler::GEM_NAMES.keys +
        ['erb', 'rdoc', 'nanoc/filters/sass/importer', 'nanoc/filters/sass/functions']

      missing = requires - described

      expect(missing).to be_empty
    end
  end
end
