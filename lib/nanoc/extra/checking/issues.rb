# encoding: utf-8

module Nanoc::Extra::Checking

  module Checkers

    autoload 'CSS',   'nanoc/extra/checking/checkers/css'
    autoload 'HTML',  'nanoc/extra/checking/checkers/html'
    autoload 'Links', 'nanoc/extra/checking/checkers/links'

    Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::CSS',   :css
    Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::HTML',  :html
    Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::Links', :links

  end

end

