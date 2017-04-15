module Nanoc::CLI::Commands::CompileListeners
  class DiffGenerator < Abstract
    # @see Listener#enable_for?
    def self.enable_for?(command_runner)
      command_runner.site.config[:enable_output_diff] || command_runner.options[:diff]
    end

    # @see Listener#start
    def start
      require 'tempfile'
      setup_diffs
      old_contents = {}
      Nanoc::Int::NotificationCenter.on(:will_write_rep, self) do |rep, path|
        old_contents[rep] = File.file?(path) ? File.read(path) : nil
      end
      Nanoc::Int::NotificationCenter.on(:rep_written, self) do |rep, binary, path, _is_created, _is_modified|
        unless binary
          new_contents = File.file?(path) ? File.read(path) : nil
          if old_contents[rep] && new_contents
            generate_diff_for(path, old_contents[rep], new_contents)
          end
          old_contents.delete(rep)
        end
      end
    end

    # @see Listener#stop
    def stop
      super

      Nanoc::Int::NotificationCenter.remove(:will_write_rep, self)
      Nanoc::Int::NotificationCenter.remove(:rep_written, self)

      teardown_diffs
    end

    protected

    def setup_diffs
      @diff_lock    = Mutex.new
      @diff_threads = []
      FileUtils.rm('output.diff') if File.file?('output.diff')
    end

    def teardown_diffs
      @diff_threads.each(&:join)
    end

    def generate_diff_for(path, old_content, new_content)
      return if old_content == new_content

      @diff_threads << Thread.new do
        # Generate diff
        diff = diff_strings(old_content, new_content)
        diff.sub!(/^--- .*/,    '--- ' + path)
        diff.sub!(/^\+\+\+ .*/, '+++ ' + path)

        # Write diff
        @diff_lock.synchronize do
          File.open('output.diff', 'a') { |io| io.write(diff) }
        end
      end
    end

    def diff_strings(a, b)
      require 'open3'

      # Create files
      Tempfile.open('old') do |old_file|
        Tempfile.open('new') do |new_file|
          # Write files
          old_file.write(a)
          old_file.flush
          new_file.write(b)
          new_file.flush

          # Diff
          cmd = ['diff', '-u', old_file.path, new_file.path]
          Open3.popen3(*cmd) do |_stdin, stdout, _stderr|
            result = stdout.read
            return (result == '' ? nil : result)
          end
        end
      end
    rescue Errno::ENOENT
      warn 'Failed to run `diff`, so no diff with the previously compiled ' \
           'content will be available.'
      nil
    end
  end
end
