module Nanoc::Routers # :nodoc:
end

Dir[File.dirname(__FILE__) + '/routers/*.rb'].sort.each { |f| require f }
