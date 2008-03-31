module Nanoc

  VERSION = '2.1'

  def self.load(*path)
    full_path = [ File.dirname(__FILE__), 'nanoc' ] + path
    Dir[File.join(full_path)].each { |f| require f }
  end

end

# Load base
Nanoc.load('base', 'enhancements.rb')
Nanoc.load('base', 'core_ext', '*.rb')
Nanoc.load('base', 'plugin.rb')
Nanoc.load('base', '*.rb')

# Load plugins
Nanoc.load('data_sources', '*.rb')
Nanoc.load('filters', '*.rb')

# Get global binding
$nanoc_binding = binding
