require 'yaml'

module YAML
  # Loads a YAML file, cleans it using Hash#clean, and returns the result
  def self.load_file_and_clean(a_filename)
    (YAML.load_file(a_filename) || {}).clean
  end
end
