module Nanoc

  VERSION = '2.0.3'

  def self.load_file(*path)
    full_path = [ File.dirname(__FILE__), 'nanoc' ] + path
    Dir[File.join(full_path)].each { |f| require f }
  end

end

# Load base
Nanoc.load_file('base', 'enhancements.rb')
Nanoc.load_file('base', 'core_ext', '*.rb')
Nanoc.load_file('base', 'plugin.rb')
Nanoc.load_file('base', '*.rb')

# Load plugins
Nanoc.load_file('data_sources', '*.rb')
Nanoc.load_file('filters', '*.rb')
Nanoc.load_file('layout_processors', '*.rb')

# Get global binding
$nanoc_binding = binding
