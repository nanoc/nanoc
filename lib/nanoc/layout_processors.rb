# Convenience function for registering filters
def register_layout_processor(*extensions, &block)
  extensions.each { |extension| $nanoc_compiler.register_layout_processor(extension, &block) }
end

# Load all filters
Dir[File.join(File.dirname(__FILE__), 'layout_processors', '*.rb')].each { |f| require f }
