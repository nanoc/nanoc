# encoding: utf-8

require 'yard'

YARD::Rake::YardocTask.new(:doc) do |yard|
  yard.files   = Dir['lib/**/*.rb']
  yard.options = [
    '--markup',     'markdown',
    '--readme',     'README.md',
    '--output-dir', 'doc/yardoc'
  ]
end
