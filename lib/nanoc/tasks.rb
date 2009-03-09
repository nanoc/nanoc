module Nanoc::Tasks # :nodoc:
end

Dir[File.dirname(__FILE__) + '/tasks/*.rb'].each { |f| load f }
Dir[File.dirname(__FILE__) + '/tasks/*.rake'].each { |f| load f }
