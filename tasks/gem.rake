# encoding: utf-8

require 'rubygems/package_task'

namespace :pkg do

  spec = eval(File.read('nanoc3.gemspec'))
  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

end
