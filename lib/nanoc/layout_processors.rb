# Load all filters
Dir[File.join(File.dirname(__FILE__), 'layout_processors', '*.rb')].each { |f| require f }
