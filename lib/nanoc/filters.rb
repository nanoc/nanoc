# Convenience function for registering filters
def register_filter(*names, &block)
  names.each { |name| $nanoc_compiler.register_filter(name, &block) }
end

# Load all filters
Dir[File.join(File.dirname(__FILE__), 'filters', '*_filter.rb')].each { |f| require f }
