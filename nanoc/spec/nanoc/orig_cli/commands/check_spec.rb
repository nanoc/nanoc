# frozen_string_literal: true

describe Nanoc::OrigCLI::Commands::Check, site: true, stdio: true do
  describe '#run' do
    before do
      File.write('Checks', "deploy_check :stale\n")
    end

    context 'without options and arguments' do
      subject { Nanoc::CLI.run(['check']) }

      context 'no issues for any checks' do
        it 'succeeds' do
          subject
        end
      end

      context 'issues for deploy check' do
        before do
          FileUtils.mkdir_p('output')
          File.write('output/asdf.txt', 'staaale')
        end

        it 'fails' do
          expect { subject }.to raise_error(Nanoc::Core::TrivialError, 'One or more checks failed')
        end
      end

      context 'issues for non-deploy check' do
        before do
          FileUtils.mkdir_p('output')
          File.write('output/asdf.txt', 'staaale')
          File.write('Checks', '')
        end

        it 'succeeds' do
          subject
        end
      end
    end
  end

  describe 'help' do
    subject { Nanoc::CLI.run(%w[help check]) }

    it 'shows --deploy as deprecated' do
      expect { subject }.to output(/--deploy.*\(deprecated\)/).to_stdout
    end
  end
end
