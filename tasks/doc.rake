# encoding: utf-8

require 'nanoc3/package'

require 'rdoc/task'
require 'yard'

namespace :doc do

  RDoc::Task.new(:rdoc => 'rdoc', :clobber_rdoc => 'rdoc:clean', :rerdoc => 'rdoc:force') do |rd|
    rd.main       = Nanoc3::Package.instance.main_documentation_file
    rd.rdoc_files = Nanoc3::Package.instance.files_in_documentation
    rd.rdoc_dir   = 'doc/rdoc'
    rd.title      = Nanoc3::Package.instance.name
  end

  YARD::Rake::YardocTask.new do |yard|
    yard.files   = Dir['lib/**/*.rb']
    yard.options = [
      '--readme',     'README.rdoc',
      '--output-dir', 'doc/yardoc'
    ]
  end

end

desc 'Alias for doc:rdoc'
task :doc => [ :'doc:rdoc' ]
