module Nanoc
  class Configuration
    FILENAME        = 'config.yaml'
    DEFAULT_CONFIG  = { :output_dir => 'output' }
    
    def initialize
      reload
    end
    
    def available?
      not @configuration.nil?
    end
    
    def reload
      @configuration = File.file?(FILENAME) ? DEFAULT_CONFIG.merge(YAML.load_file_and_clean(FILENAME)) : nil
    end
    
    def [](a_key)
      @configuration[a_key]
    end
    
  end
end
