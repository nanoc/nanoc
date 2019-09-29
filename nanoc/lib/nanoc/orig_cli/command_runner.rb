# frozen_string_literal: true

module Nanoc::OrigCLI
  # A command runner subclass for Nanoc commands that adds Nanoc-specific
  # convenience methods and error handling.
  #
  # @api private
  class CommandRunner < ::Cri::CommandRunner
    # @see http://rubydoc.info/gems/cri/Cri/CommandRunner#call-instance_method
    #
    # @return [void]
    def call
      Nanoc::CLI::ErrorHandler.handle_while do
        run
      end
    end

    # @return [Boolean] true if the current working directory is a Nanoc site
    #   directory, false otherwise
    def in_site_dir?
      Nanoc::Core::SiteLoader.cwd_is_nanoc_site?
    end

    def self.find_site_dir
      start_here = Dir.pwd

      here = start_here
      until Nanoc::Core::SiteLoader.cwd_is_nanoc_site?
        Dir.chdir('..')
        return nil if Dir.pwd == here

        here = Dir.pwd
      end
      here
    ensure
      Dir.chdir(start_here)
    end

    def self.enter_site_dir
      dir = find_site_dir
      if dir.nil?
        raise ::Nanoc::Core::TrivialError, 'The current working directory, nor any of its parents, seems to be a Nanoc site.'
      end

      return if Dir.getwd == dir

      $stderr.puts "Using Nanoc site in #{dir}"
      Dir.chdir(dir)
    end

    # Asserts that the current working directory contains a site and loads the site into memory.
    #
    # @return [void]
    def load_site
      self.class.enter_site_dir

      $stderr.print 'Loading site… '
      $stderr.flush
      site = Nanoc::Core::SiteLoader.new.new_from_cwd

      $stderr.puts 'done'
      site
    end

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @see Nanoc::OrigCLI.debug?
    def debug?
      Nanoc::OrigCLI.debug?
    end
  end
end
