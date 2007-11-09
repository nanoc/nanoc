# Load all filters
Dir[File.join(File.dirname(__FILE__), 'filters', '*.rb')].each { |f| require f }
