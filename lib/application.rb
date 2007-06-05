module Nanoc
  class Application

    def self.ensure_in_site
      unless in_site?
        $stderr.puts 'ERROR: The current working directory does not seem ' +
          'to be a valid/complete nanoc site directory; aborting.' unless $quiet
        exit
      end
    end

    def self.ensure_in_1_dot_2_site
      unless in_1_dot_2_site?
        $stderr.puts 'ERROR: The current working directory is outdated ' +
          'and needs to be updated (nanoc update_site); aborting.' unless $quiet
        exit
      end
    end

    def self.in_site?
      return false unless File.directory?('content')
      return false unless File.directory?('layouts')
      return false unless File.directory?('lib')
      return false unless File.directory?('output')
      return false unless File.directory?('tasks')
      return false unless File.directory?('templates')

      return false unless File.file?('config.yaml')
      return false unless File.file?('meta.yaml')
      return false unless File.file?('Rakefile')

      true
    end

    def self.in_1_dot_2_site?
      return false unless self.in_site?

      return false unless Dir['content/**/meta.yaml'].empty?
      
      true
    end

  end
end
