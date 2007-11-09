module Nanoc

  VERSION = '1.7'

end

# Load base
require File.dirname(__FILE__) + '/nanoc/base/enhancements.rb'
Dir[File.join(File.dirname(__FILE__), 'nanoc', 'base', '*.rb')].each { |f| require f }

# Create site
$nanoc_site = Nanoc::Site.from_cwd

# Create creator
$nanoc_creator = Nanoc::Creator.new

# Load extras
require File.dirname(__FILE__) + '/nanoc/data_sources.rb'
require File.dirname(__FILE__) + '/nanoc/filters.rb'
require File.dirname(__FILE__) + '/nanoc/layout_processors.rb'
