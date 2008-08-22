module Nanoc::DataSources # :nodoc:
end

Dir[File.dirname(__FILE__) + '/data_sources/*.rb'].sort.each { |f| require f }
