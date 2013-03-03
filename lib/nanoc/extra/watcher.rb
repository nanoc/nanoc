# encoding: utf-8

module Nanoc::Extra

  # Watches the working directory for changes and recompiles if necessary.
  class Watcher

    # Runs the watcher.
    #
    # @return [void]
    def run
      require 'listen'
      require 'pathname'

      require_site

      # Rebuild once
      print "Watcher started; compiling the entire site… "
      self.recompile

      # Get directories to watch
      dirs_to_watch  = self.watcher_config[:dirs_to_watch]  || ['content', 'layouts', 'lib']
      files_to_watch = self.watcher_config[:files_to_watch] || ['nanoc.yaml', 'config.yaml', 'Rules', 'rules', 'Rules.rb', 'rules.rb']
      files_to_watch = Regexp.new(files_to_watch.map { |name| "#{Regexp.quote(name)}$"}.join("|"))
      ignore_dir = Regexp.new(Dir.glob("*").map{|dir| dir if File::ftype(dir) == "directory" }.compact.join("|"))

      # Watch
      puts "Watching for changes…"

      callback = Proc.new do |modified, added, removed|
        rebuilder = self.rebuilder_proc
        rebuilder.call(modified[0]) if modified[0]
        rebuilder.call(added[0]) if added[0]
        rebuilder.call(removed[0]) if removed[0]
      end

      listener = Listen::MultiListener.new(*dirs_to_watch).change(&callback)
      listener_root = Listen::MultiListener.new('', :filter => files_to_watch, :ignore => ignore_dir).change(&callback)

      begin
        listener_root.start(false)
        listener.start
      rescue Interrupt
        listener.stop
        listener_root.stop
      end
    end

  protected

    def watcher_config
      @_watcher_config ||= self.site.config[:watcher] || {}
    end

    def notify(message)
      @_notifier ||= Nanoc::Extra::UserNotifier.new
      @_notifier.notify(message)
    end

    def recompile
      begin
        start = Time.now
        site = Nanoc::Site.new('.')
        site.compile

        # Notify done
        notify_on_compilation_success = self.watcher_config.fetch(:notify_on_compilation_success) { true }
        if notify_on_compilation_success
          self.notify('Compilation complete')
        end

        # Show time spent
        time_spent = ((Time.now - start)*1000.0).round
        puts "done in #{format '%is %ims', *(time_spent.divmod(1000))}"
      rescue Exception => e
        # Notify done
        notify_on_compilation_failure = self.watcher_config.fetch(:notify_on_compilation_failure) { true }
        if notify_on_compilation_failure
          self.notify('Compilation failed')
        end

        # Show error
        puts
        Nanoc::CLI::ErrorHandler.print_error(e)
        puts
      end
    end

    def rebuilder_proc
      rebuilder = lambda do |file_path|
        # Notify
        filename = ::Pathname.new(file_path).relative_path_from(::Pathname.new(Dir.getwd)).to_s
        print "Change detected to #{filename}; recompiling… "

        # Compile start
        self.recompile
      end
    end

  end

end
