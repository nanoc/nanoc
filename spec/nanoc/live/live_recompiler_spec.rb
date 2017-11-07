# frozen_string_literal: true

describe Nanoc::Live::LiveRecompiler, site: true, stdio: true do
  it 'detects content changes' do
    command = nil
    command_runner = Nanoc::CLI::CommandRunner.new({}, [], command)
    live_recompiler = described_class.new(command_runner: command_runner)

    pid = fork do
      trap(:INT) { exit(0) }
      live_recompiler.run
    end

    # FIXME: wait is ugly
    sleep 0.5

    File.write('content/lol.html', 'hej')
    sleep 0.1 until File.file?('output/lol.html')
    expect(File.read('output/lol.html')).to eq('hej')

    sleep 1.0 # HFS+ mtime resolution is 1s
    File.write('content/lol.html', 'bye')
    sleep 0.1 until File.read('output/lol.html') == 'bye'

    # Stop
    Process.kill('INT', pid)
    Process.waitpid(pid)
  end

  it 'detects rules changes' do
    command = nil
    command_runner = Nanoc::CLI::CommandRunner.new({}, [], command)
    live_recompiler = described_class.new(command_runner: command_runner)

    pid = fork do
      trap(:INT) { exit(0) }
      live_recompiler.run
    end

    # FIXME: wait is ugly
    sleep 0.5

    File.write('content/lol.html', '<%= "hej" %>')
    sleep 0.1 until File.file?('output/lol.html')
    expect(File.read('output/lol.html')).to eq('<%= "hej" %>')

    sleep 1.0 # HFS+ mtime resolution is 1s
    File.write('Rules', <<~RULES)
      compile '/**/*' do
        filter :erb
        write item.identifier
      end
    RULES
    sleep 0.1 until File.read('output/lol.html') == 'hej'

    # Stop
    Process.kill('INT', pid)
    Process.waitpid(pid)
  end

  it 'detects config changes' do
    command = nil
    command_runner = Nanoc::CLI::CommandRunner.new({}, [], command)
    live_recompiler = described_class.new(command_runner: command_runner)

    File.write('nanoc.yaml', 'site_name: Oldz')
    File.write('content/lol.html', '<%= @config[:site_name] %>')
    File.write('Rules', <<~RULES)
      compile '/**/*' do
        filter :erb
        write item.identifier
      end
    RULES

    pid = fork do
      trap(:INT) { exit(0) }
      live_recompiler.run
    end

    # FIXME: wait is ugly
    sleep 0.5

    sleep 0.1 until File.file?('output/lol.html')
    expect(File.read('output/lol.html')).to eq('Oldz')

    sleep 1.0 # HFS+ mtime resolution is 1s
    File.write('nanoc.yaml', 'site_name: Newz')
    sleep 0.1 until File.read('output/lol.html') == 'Newz'

    # Stop
    Process.kill('INT', pid)
    Process.waitpid(pid)
  end

  it 'detects config changes' do
    command = nil
    command_runner = Nanoc::CLI::CommandRunner.new({}, [], command)
    live_recompiler = described_class.new(command_runner: command_runner)

    FileUtils.mkdir_p('lib')
    File.write('lib/lol.rb', 'def greeting; "hi"; end')
    File.write('content/lol.html', '<%= greeting %>')
    File.write('Rules', <<~RULES)
      compile '/**/*' do
        filter :erb
        write item.identifier
      end
    RULES

    pid = fork do
      trap(:INT) { exit(0) }
      live_recompiler.run
    end

    # FIXME: wait is ugly
    sleep 0.5

    sleep 0.1 until File.file?('output/lol.html')
    expect(File.read('output/lol.html')).to eq('hi')

    sleep 1.0 # HFS+ mtime resolution is 1s
    File.write('lib/lol.rb', 'def greeting; "yo"; end')
    sleep 0.1 until File.read('output/lol.html') == 'yo'

    # Stop
    Process.kill('INT', pid)
    Process.waitpid(pid)
  end
end
