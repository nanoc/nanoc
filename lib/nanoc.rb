module Nanoc

  # The current nanoc version.
  VERSION = '2.1'

  # Requires the given Ruby files at the specified path.
  #
  # +path+:: An array containing path segments. This path is relative to the
  #          directory this file (nanoc.rb) is in. Can contain wildcards.
  def self.load(*path)
    full_path = [ File.dirname(__FILE__), 'nanoc' ] + path
    Dir[File.join(full_path)].each { |f| require f }
  end

end

# Load base
Nanoc.load('base', 'enhancements.rb')
Nanoc.load('base', 'proxy.rb')
Nanoc.load('base', 'core_ext', '*.rb')
Nanoc.load('base', 'plugin.rb')
Nanoc.load('base', '*.rb')

# Load plugins
Nanoc.load('data_sources', '*.rb')
Nanoc.load('filters', '*.rb')
Nanoc.load('routers', '*.rb')
