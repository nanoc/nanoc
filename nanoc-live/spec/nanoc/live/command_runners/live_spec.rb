# frozen_string_literal: true

describe Nanoc::Live::CommandRunners::Live, fork: true, site: true, stdio: true do
  def run_cmd
    pipe_stdout_read, pipe_stdout_write = IO.pipe
    pid = fork do
      trap(:INT) { exit(0) }
      pipe_stdout_read.close
      $stdout = pipe_stdout_write
      Nanoc::CLI.run(['live'])
    end
    pipe_stdout_write.close

    # Wait until ready
    Timeout.timeout(5) do
      progress = 0
      pipe_stdout_read.each_line do |line|
        progress += 1 if line.start_with?('Listening for lib/ changes')
        progress += 1 if line.start_with?('Listening for site changes')
        progress += 1 if line.start_with?('View the site at')
        break if progress == 3
      end
    end
    sleep 0.5 # Still needs time to warm up…

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

  it 'listens for websocket connections' do
    run_cmd do
      socket = TCPSocket.new('localhost', 35_729)
      expect(socket).not_to be_closed
    end
  end
end
