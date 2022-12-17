# frozen_string_literal: true

RSpec.describe Guard::Nanoc do
  around do |example|
    Dir.mktmpdir('nanoc-test') do |dir|
      __nanoc_core_chdir(dir) do
        Nanoc::CLI.run(%w[create-site foo])
        __nanoc_core_chdir('foo') do
          example.run
        end
      end
    end
  end

  before do
    allow(Process).to receive(:fork) do |_args, &block|
      @_fork_block = block
    end

    allow(Process).to receive(:waitpid) do
      @_fork_block.call
    end

    allow(Guard::Compat::UI).to receive(:notify)
    allow(Guard::Compat::UI).to receive(:error)
    allow(Guard::Compat::UI).to receive(:info)
  end

  describe '#start' do
    context 'with no errors' do
      it 'outputs success' do
        expect(Guard::Compat::UI).to receive(:info).with(/Compilation succeeded/)
        subject.start
      end

      it 'notifies about success' do
        expect(Guard::Compat::UI).to receive(:notify).with(/Compilation succeeded/, anything)
        subject.start
      end
    end

    context 'with errors' do
      before do
        File.write('layouts/default.html', '<%= raise "boom" %>')
      end

      it 'outputs failure' do
        expect(Guard::Compat::UI).to receive(:error).with(/Compilation failed/)
        subject.start
      end

      it 'notifies about failure' do
        expect(Guard::Compat::UI).to receive(:notify).with(/Compilation FAILED/, anything)
        subject.start
      end
    end
  end

  describe 'command' do
    it 'has an option set that is a superset of the view command’s options' do
      view_cmd = Nanoc::CLI.root_command.command_named('view')
      live_cmd = described_class.live_cmd

      expect(live_cmd.option_definitions).not_to eq(view_cmd.option_definitions)
    end
  end
end
