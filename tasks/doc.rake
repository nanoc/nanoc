# encoding: utf-8

require 'yard'

YARD::Rake::YardocTask.new(:doc) do |yard|
  yard.files   = Dir['lib/**/*.rb']
  yard.options = [
    '--markup',          'markdown',
    '--markup-provider', 'kramdown',
    '--charset',         'utf-8',
    '--readme',          'README.md',
    '--files',           'NEWS.md,LICENSE',
    '--output-dir',      'doc/yardoc',
    '--template-path',   'doc/yardoc_templates',
    '--load',            'doc/yardoc_handlers/identifier.rb',
    '--query',           '@api.text != "private" && (object.respond_to?(:children) ? object.children.select { |c| !c.has_tag?(:api) || c.tag(:api).text != "private" }.any? : true)',
  ]
end
