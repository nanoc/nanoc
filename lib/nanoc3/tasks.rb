# encoding: utf-8

require 'nanoc3'

module Nanoc3::Tasks
end

Dir[File.dirname(__FILE__) + '/tasks/**/*.rb'].each   { |f| load f }
Dir[File.dirname(__FILE__) + '/tasks/**/*.rake'].each { |f| load f }
