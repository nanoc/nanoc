require 'nanoc3/package'

require 'rdoc/task'

namespace :doc do

  RDoc::Task.new(:rdoc => 'rdoc', :clobber_rdoc => 'rdoc:clean', :rerdoc => 'rdoc:force') do |rd|
    rd.main       = Nanoc3::Package.instance.main_documentation_file
    rd.rdoc_files = Nanoc3::Package.instance.files
    rd.rdoc_dir   = 'doc/rdoc'
    rd.title      = Nanoc3::Package.instance.name
  end

  desc 'Build the YARD documentation'
  task :yardoc do
    # Clean
    FileUtils.rm_r 'doc' if File.exist?('doc')

    # Get options
    yardoc_files   = Dir.glob('lib/nanoc3/base/**/*.rb') +
                     Dir.glob('lib/nanoc3/data_sources/**/*.rb') +
                     Dir.glob('lib/nanoc3/extra/**/*.rb') +
                     Dir.glob('lib/nanoc3/helpers/**/*.rb')
    yardoc_options = [
      '--verbose',
      '--readme', 'README'
    ]

    # Build
    system *[ 'yardoc', yardoc_files, yardoc_options ].flatten
  end

end

desc 'Alias for doc:rdoc'
task :doc => [ :'doc:rdoc' ]
