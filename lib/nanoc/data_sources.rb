# Load all data sources
Dir[File.join(File.dirname(__FILE__), 'data_sources', '*.rb')].each { |f| require f }
