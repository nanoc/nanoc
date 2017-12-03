# frozen_string_literal: true

describe Nanoc::CLI::StackTraceWriter do
  subject(:writer) do
    described_class.new(io, forwards: forwards)
  end

  let(:io) { StringIO.new }
  let(:forwards) { true }

  describe '#write' do
    let(:exception) do
      backtrace_generator = lambda do |af|
        if af.zero?
          raise 'finally!'
        else
          backtrace_generator.call(af - 1)
        end
      end

      begin
        backtrace_generator.call(3)
      rescue => e
        return e
      end
    end

    subject { writer.write(exception, verbose: verbose) }

    let(:verbose) { false }

    context 'backwards' do
      let(:forwards) { false }

      context 'verbose' do
        let(:verbose) { true }

        it 'starts with zero' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(start_with('  0. '))
        end

        it 'has more recent stack frames at the top' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  0\. /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d+.*$\n  1\. /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d}m))
        end

        it 'has more than 10 stack frames' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  11\. }))
        end

        it 'does not contain a see-more explanation' do
          subject
          expect(io.string).not_to match(/crash\.log/)
        end
      end

      context 'not verbose' do
        let(:verbose) { false }

        it 'starts with zero' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(start_with('  0. '))
        end

        it 'has more recent stack frames at the top' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  0\. /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d+.*$\n  1\. /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d}m))
        end

        it 'has not more than 10 stack frames' do
          subject
          expect(io.string).not_to match(/^  11\. /)
        end

        it 'does not contain a see-more explanation' do
          subject
          expect(io.string).to include(" lines omitted (see crash.log for details)\n")
        end
      end
    end

    context 'forwards' do
      let(:forwards) { true }

      context 'verbose' do
        let(:verbose) { true }

        it 'ends with most recent line' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  1\. from /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d+.*$\n  /.+/spec/nanoc/cli}m))
        end

        it 'has more recent stack frames at the bottom' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  2\. from /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d+.*$\n  1\. from /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d}m))
        end

        it 'has more than 10 stack frames' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  11\. from }))
        end

        it 'does not contain a see-more explanation' do
          subject
          expect(io.string).not_to match(/crash\.log/)
        end
      end

      context 'not verbose' do
        let(:verbose) { false }

        it 'ends with most recent line' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  1\. from /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d+.*$\n  /.+/spec/nanoc/cli}m))
        end

        it 'has more recent stack frames at the top' do
          expect { subject }
            .to change { io.string }
            .from('')
            .to(match(%r{^  2\. from /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d+.*$\n  1\. from /.+/spec/nanoc/cli/stack_trace_writer_spec\.rb:\d}m))
        end

        it 'has not more than 10 stack frames' do
          subject
          expect(io.string).not_to match(/^  11\. from /)
        end

        it 'does not contain a see-more explanation' do
          subject
          expect(io.string).to include(" lines omitted (see crash.log for details)\n")
        end
      end
    end
  end
end
