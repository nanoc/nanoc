describe Nanoc::CLI::Commands::View, site: true, stdio: true do
  describe '#run' do
    def run_nanoc_cmd(cmd)
      pid = fork { Nanoc::CLI.run(cmd) }

      # Wait for server to start up
      10.times do
        begin
          Net::HTTP.get('0.0.0.0', '/', 50_385)
        rescue Errno::ECONNREFUSED
          sleep 0.1
          retry
        end
        break
      end

      yield
    ensure
      Process.kill('TERM', pid)
    end

    it 'serves /index.html as /' do
      File.write('output/index.html', 'Hello there! Nanoc loves you! <3')
      run_nanoc_cmd(['view', '--port', '50385']) do
        expect(Net::HTTP.get('0.0.0.0', '/', 50_385)).to eql('Hello there! Nanoc loves you! <3')
      end
    end
  end
end
