# encoding: utf-8

class Nanoc::CLI::Commands::WatchTest < Nanoc::TestCase

  def test_run
    with_site do |site|
      # Create site
      File.open('content/index.md', 'w') { |io| io.write('O hai!') }

      # Start watcher
      watch_thread = Thread.new do
        Thread.handle_interrupt(Interrupt => :immediate) do
          Nanoc::CLI.run %w( watch )
        end
      end

      # Wait until initial compile finishes
      self.wait_until_exists('output/index.html')

      # Modify and wait for recompile
      File.open('content/about.html', 'w') { |io| io.write('Hello there!') }
      self.wait_until_exists('output/about/index.html')

      # Stop watcher
      watch_thread.raise Interrupt
      #watch_thread.kill
    end
  end

  def wait_until_exists(filename)
    20.times do
      break if File.file?(filename)
      sleep 0.2
    end
    if !File.file?(filename)
      raise RuntimeError, "Expected #{filename} to appear but it didn't :("
    end
  end

end
