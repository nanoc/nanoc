# frozen_string_literal: true

require 'net/http'

describe Nanoc::CLI::Commands::View, site: true, stdio: true do
  describe '#run' do
    def run_nanoc_cmd(cmd)
      pid = fork { Nanoc::CLI.run(cmd) }

      # Wait for server to start up
      20.times do |i|
        begin
          Net::HTTP.get('127.0.0.1', '/', 50_385)
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET
          sleep(0.1 * 1.2**i)
          retry
        end
        break
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
  end
end
