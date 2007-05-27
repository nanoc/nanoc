module Nanoc
  class Configuration

    FILENAME                = 'config.yaml'
    CONFIGURATION_DEFAULTS  = { :output_dir => 'output' }

    def self.available?
      not @@configuration.nil?
    end

    def self.reload
      if File.file?(FILENAME)
        @@configuration = CONFIGURATION_DEFAULTS.merge(YAML.load_file_and_clean(FILENAME))
      else
        @@configuration = CONFIGURATION_DEFAULTS
      end
    end

    def self.[](a_key)
      @@configuration[a_key]
    end

  end
end
