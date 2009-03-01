namespace :doc do

  desc 'Build the RDoc documentation'
  task :rdoc do
    # Clean
    FileUtils.rm_r 'doc'

    # Build
    rdoc_files   = GemSpec.extra_rdoc_files + [ 'lib' ]
    rdoc_options = GemSpec.rdoc_options
    system *[ 'rdoc', rdoc_files, rdoc_options ].flatten
  end

end

desc 'Alias for doc:rdoc'
task :doc => [ :'doc:rdoc' ]
