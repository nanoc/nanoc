# encoding: utf-8

module Nanoc3::Filters

  autoload 'AsciiDoc',        'nanoc3/filters/asciidoc'
  autoload 'BlueCloth',       'nanoc3/filters/bluecloth'
  autoload 'CodeRay',         'nanoc3/filters/coderay'
  autoload 'ColorizeSyntax',  'nanoc3/filters/colorize_syntax'
  autoload 'ERB',             'nanoc3/filters/erb'
  autoload 'Erubis',          'nanoc3/filters/erubis'
  autoload 'Haml',            'nanoc3/filters/haml'
  autoload 'Kramdown',        'nanoc3/filters/kramdown'
  autoload 'Less',            'nanoc3/filters/less'
  autoload 'Markaby',         'nanoc3/filters/markaby'
  autoload 'Maruku',          'nanoc3/filters/maruku'
  autoload 'Mustache',        'nanoc3/filters/mustache'
  autoload 'Rainpress',       'nanoc3/filters/rainpress'
  autoload 'RDiscount',       'nanoc3/filters/rdiscount'
  autoload 'RDoc',            'nanoc3/filters/rdoc'
  autoload 'Redcarpet',       'nanoc3/filters/redcarpet'
  autoload 'RedCloth',        'nanoc3/filters/redcloth'
  autoload 'RelativizePaths', 'nanoc3/filters/relativize_paths'
  autoload 'RubyPants',       'nanoc3/filters/rubypants'
  autoload 'Sass',            'nanoc3/filters/sass'
  autoload 'Slim',            'nanoc3/filters/slim'
  autoload 'Typogruby',       'nanoc3/filters/typogruby'
  autoload 'UglifyJS',        'nanoc3/filters/uglify_js'

  Nanoc3::Filter.register '::Nanoc3::Filters::AsciiDoc',        :asciidoc
  Nanoc3::Filter.register '::Nanoc3::Filters::BlueCloth',       :bluecloth
  Nanoc3::Filter.register '::Nanoc3::Filters::CodeRay',         :coderay
  Nanoc3::Filter.register '::Nanoc3::Filters::ColorizeSyntax',  :colorize_syntax
  Nanoc3::Filter.register '::Nanoc3::Filters::ERB',             :erb
  Nanoc3::Filter.register '::Nanoc3::Filters::Erubis',          :erubis
  Nanoc3::Filter.register '::Nanoc3::Filters::Haml',            :haml
  Nanoc3::Filter.register '::Nanoc3::Filters::Kramdown',        :kramdown
  Nanoc3::Filter.register '::Nanoc3::Filters::Less',            :less
  Nanoc3::Filter.register '::Nanoc3::Filters::Markaby',         :markaby
  Nanoc3::Filter.register '::Nanoc3::Filters::Maruku',          :maruku
  Nanoc3::Filter.register '::Nanoc3::Filters::Mustache',        :mustache
  Nanoc3::Filter.register '::Nanoc3::Filters::Rainpress',       :rainpress
  Nanoc3::Filter.register '::Nanoc3::Filters::RDiscount',       :rdiscount
  Nanoc3::Filter.register '::Nanoc3::Filters::RDoc',            :rdoc
  Nanoc3::Filter.register '::Nanoc3::Filters::Redcarpet',       :redcarpet
  Nanoc3::Filter.register '::Nanoc3::Filters::RedCloth',        :redcloth
  Nanoc3::Filter.register '::Nanoc3::Filters::RelativizePaths', :relativize_paths
  Nanoc3::Filter.register '::Nanoc3::Filters::RubyPants',       :rubypants
  Nanoc3::Filter.register '::Nanoc3::Filters::Sass',            :sass
  Nanoc3::Filter.register '::Nanoc3::Filters::Slim',            :slim
  Nanoc3::Filter.register '::Nanoc3::Filters::Typogruby',       :typogruby
  Nanoc3::Filter.register '::Nanoc3::Filters::UglifyJS',        :uglify_js

end
