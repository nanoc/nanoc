module Nanoc::Filters # :nodoc:
end

Dir[File.dirname(__FILE__) + '/filters/*.rb'].sort.each { |f| require f }
