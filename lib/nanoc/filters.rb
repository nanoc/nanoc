# encoding: utf-8

module Nanoc::Filters

  autoload 'AsciiDoc',        'nanoc/filters/asciidoc'
  autoload 'BlueCloth',       'nanoc/filters/bluecloth'
  autoload 'CodeRay',         'nanoc/filters/coderay'
  autoload 'ColorizeSyntax',  'nanoc/filters/colorize_syntax'
  autoload 'CoffeeScript',    'nanoc/filters/coffeescript'
  autoload 'ERB',             'nanoc/filters/erb'
  autoload 'Erubis',          'nanoc/filters/erubis'
  autoload 'Haml',            'nanoc/filters/haml'
  autoload 'Handlebars',      'nanoc/filters/handlebars'
  autoload 'Kramdown',        'nanoc/filters/kramdown'
  autoload 'Less',            'nanoc/filters/less'
  autoload 'Markaby',         'nanoc/filters/markaby'
  autoload 'Maruku',          'nanoc/filters/maruku'
  autoload 'Mustache',        'nanoc/filters/mustache'
  autoload 'Pandoc',          'nanoc/filters/pandoc'
  autoload 'Rainpress',       'nanoc/filters/rainpress'
  autoload 'RDiscount',       'nanoc/filters/rdiscount'
  autoload 'RDoc',            'nanoc/filters/rdoc'
  autoload 'Redcarpet',       'nanoc/filters/redcarpet'
  autoload 'RedCloth',        'nanoc/filters/redcloth'
  autoload 'RelativizePaths', 'nanoc/filters/relativize_paths'
  autoload 'RubyPants',       'nanoc/filters/rubypants'
  autoload 'Sass',            'nanoc/filters/sass'
  autoload 'Slim',            'nanoc/filters/slim'
  autoload 'Typogruby',       'nanoc/filters/typogruby'
  autoload 'UglifyJS',        'nanoc/filters/uglify_js'
  autoload 'XSL',             'nanoc/filters/xsl'
  autoload 'YUICompressor',   'nanoc/filters/yui_compressor'

  Nanoc::Filter.register '::Nanoc::Filters::AsciiDoc',        :asciidoc
  Nanoc::Filter.register '::Nanoc::Filters::BlueCloth',       :bluecloth
  Nanoc::Filter.register '::Nanoc::Filters::CodeRay',         :coderay
  Nanoc::Filter.register '::Nanoc::Filters::ColorizeSyntax',  :colorize_syntax
  Nanoc::Filter.register '::Nanoc::Filters::CoffeeScript',    :coffeescript
  Nanoc::Filter.register '::Nanoc::Filters::ERB',             :erb
  Nanoc::Filter.register '::Nanoc::Filters::Erubis',          :erubis
  Nanoc::Filter.register '::Nanoc::Filters::Haml',            :haml
  Nanoc::Filter.register '::Nanoc::Filters::Handlebars',      :handlebars
  Nanoc::Filter.register '::Nanoc::Filters::Kramdown',        :kramdown
  Nanoc::Filter.register '::Nanoc::Filters::Less',            :less
  Nanoc::Filter.register '::Nanoc::Filters::Markaby',         :markaby
  Nanoc::Filter.register '::Nanoc::Filters::Maruku',          :maruku
  Nanoc::Filter.register '::Nanoc::Filters::Mustache',        :mustache
  Nanoc::Filter.register '::Nanoc::Filters::Pandoc',          :pandoc
  Nanoc::Filter.register '::Nanoc::Filters::Rainpress',       :rainpress
  Nanoc::Filter.register '::Nanoc::Filters::RDiscount',       :rdiscount
  Nanoc::Filter.register '::Nanoc::Filters::RDoc',            :rdoc
  Nanoc::Filter.register '::Nanoc::Filters::Redcarpet',       :redcarpet
  Nanoc::Filter.register '::Nanoc::Filters::RedCloth',        :redcloth
  Nanoc::Filter.register '::Nanoc::Filters::RelativizePaths', :relativize_paths
  Nanoc::Filter.register '::Nanoc::Filters::RubyPants',       :rubypants
  Nanoc::Filter.register '::Nanoc::Filters::Sass',            :sass
  Nanoc::Filter.register '::Nanoc::Filters::Slim',            :slim
  Nanoc::Filter.register '::Nanoc::Filters::Typogruby',       :typogruby
  Nanoc::Filter.register '::Nanoc::Filters::UglifyJS',        :uglify_js
  Nanoc::Filter.register '::Nanoc::Filters::XSL',             :xsl
  Nanoc::Filter.register '::Nanoc::Filters::YUICompressor',   :yui_compressor

end
