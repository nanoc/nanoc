# encoding: utf-8

require 'yard'

YARD::Rake::YardocTask.new(:doc) do |yard|
  yard.files   = Dir['lib/**/*.rb']
  yard.options = [
    '--markup',        'markdown',
    '--readme',        'README.md',
    '--files',         'NEWS.md,LICENSE',
    '--output-dir',    'doc/yardoc',
    '--template-path', 'doc/yardoc_templates'
  ]
end
