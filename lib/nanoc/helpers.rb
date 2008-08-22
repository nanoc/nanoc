module Nanoc::Helpers # :nodoc:
end

Dir[File.dirname(__FILE__) + '/helpers/*.rb'].sort.each { |f| require f }
