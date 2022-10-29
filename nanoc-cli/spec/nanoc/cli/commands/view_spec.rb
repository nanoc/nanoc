# frozen_string_literal: true

require 'net/http'

describe Nanoc::CLI::Commands::View, fork: true, site: true, stdio: true do
  describe '#run' do
    def run_nanoc_cmd(cmd)
      pid = fork { Nanoc::CLI.run(cmd) }

      # Wait for server to start up
      20.times do |i|
        begin
          Net::HTTP.get('127.0.0.1', '/', 50_385)
          break
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET
          sleep(0.1 * 1.1**i)
          next
        end

        raise 'Server did not start up in time'
      end

      yield
    ensure
      Process.kill('TERM', pid)
    end

    context 'default configuration' do
      it 'serves /index.html as /' do
        File.write('output/index.html', 'Hello there! Nanoc loves you! <3')
        run_nanoc_cmd(['view', '--port', '50385']) do
          expect(Net::HTTP.get('127.0.0.1', '/', 50_385)).to eql('Hello there! Nanoc loves you! <3')
        end
      end

      it 'does not serve /index.xhtml as /' do
        File.write('output/index.xhtml', 'Hello there! Nanoc loves you! <3')
        run_nanoc_cmd(['view', '--port', '50385']) do
          expect(Net::HTTP.get('127.0.0.1', '/', 50_385)).to eql("File not found: /\n")
        end
      end
    end

    context 'index_filenames including index.xhtml' do
      before do
        File.write('nanoc.yaml', 'index_filenames: [index.xhtml]')
      end

      it 'serves /index.xhtml as /' do
        File.write('output/index.xhtml', 'Hello there! Nanoc loves you! <3')
        run_nanoc_cmd(['view', '--port', '50385']) do
          expect(Net::HTTP.get('127.0.0.1', '/', 50_385)).to eql('Hello there! Nanoc loves you! <3')
        end
      end
    end

    it 'does not serve other files as /' do
      File.write('output/index.html666', 'Hello there! Nanoc loves you! <3')
      run_nanoc_cmd(['view', '--port', '50385']) do
        expect(Net::HTTP.get('127.0.0.1', '/', 50_385)).to eql("File not found: /\n")
      end
    end

    it 'does not crash when output dir does not exist and --live-reload is given' do
      FileUtils.rm_rf('output')
      run_nanoc_cmd(['view', '--port', '50385', '--live-reload']) do
        expect(Net::HTTP.get('127.0.0.1', '/', 50_385)).to eql("File not found: /\n")
      end
    end

    it 'does not listen on non-local interfaces' do
      addresses = Socket.getifaddrs.map(&:addr).compact.select(&:ipv4?).map(&:ip_address)
      non_local_addresses = addresses - ['127.0.0.1']

      if non_local_addresses.empty?
        skip 'Need non-local network interfaces for this spec'
      end

      run_nanoc_cmd(['view', '--port', '50385']) do
        expect do
          Net::HTTP.start(non_local_addresses[0], 50_385, open_timeout: 0.2) do |http|
            request = Net::HTTP::Get.new('/')
            http.request(request)
          end
        end.to raise_error(/Failed to open TCP connection|execution expired/)
      end
    end
  end
end
