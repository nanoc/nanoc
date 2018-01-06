# frozen_string_literal: true

describe Nanoc::Live::Commands::Live, site: true, stdio: true do
  def run_cmd
    pid = fork do
      trap(:INT) { exit(0) }

      # TODO: Use Nanoc::CLI.run instead (when --watch is no longer experimental)
      options = { watch: true }
      arguments = []
      cmd = nil
      cmd_runner = described_class.new(options, arguments, cmd)
      cmd_runner.run
    end

    # FIXME: wait is ugly
    sleep 0.5

    begin
      yield
    ensure
      Process.kill('INT', pid)
      Process.waitpid(pid)
    end
  end

  it 'watches' do
    run_cmd do
      File.write('content/lol.html', 'hej')
      sleep_until { File.file?('output/lol.html') }
      expect(File.read('output/lol.html')).to eq('hej')

      sleep 1.0 # HFS+ mtime resolution is 1s
      File.write('content/lol.html', 'bye')
      sleep_until { File.read('output/lol.html') == 'bye' }
    end
  end

  it 'listens' do
    run_cmd do
      File.write('content/lol.html', 'hej')
      sleep_until { File.file?('output/lol.html') }
      expect(File.read('output/lol.html')).to eq('hej')

      res = Net::HTTP.get_response(URI.parse('http://127.0.0.1:3000/lol.html'))
      expect(res.code).to eq('200')
      expect(res.body).to eq('hej')
    end
  end

  it 'receives websocket connections' do
    # TODO
  end
end
