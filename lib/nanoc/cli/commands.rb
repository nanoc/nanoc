Dir[File.dirname(__FILE__) + '/commands/*.rb'].sort.each { |f| require f }
