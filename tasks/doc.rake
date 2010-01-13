# encoding: utf-8

require 'yard'

YARD::Rake::YardocTask.new(:doc) do |yard|
  yard.files   = Dir['lib/**/*.rb']
  yard.options = [
    '--readme',     'README.rdoc',
    '--output-dir', 'doc/yardoc'
  ]
end
