namespace :doc do

  desc 'Build the RDoc documentation'
  task :rdoc do
    # Clean
    FileUtils.rm_r 'doc' if File.exist?('doc')

    # Build
    rdoc_files   = GemSpec.extra_rdoc_files + [ 'lib' ]
    rdoc_options = GemSpec.rdoc_options
    system *[ 'rdoc', rdoc_files, rdoc_options ].flatten
  end

  desc 'Build the YARD documentation'
  task :yardoc do
    # Clean
    FileUtils.rm_r 'doc' if File.exist?('doc')

    # Get options
    yardoc_files   = Dir.glob('lib/nanoc/base/**/*.rb') +
                     Dir.glob('lib/nanoc/data_sources/**/*.rb') +
                     Dir.glob('lib/nanoc/extra/**/*.rb') +
                     Dir.glob('lib/nanoc/helpers/**/*.rb')
    puts yardoc_files.join("\n- ")
    yardoc_options = [
      '--verbose',
      '--readme', 'README'
    ]

    # Build
    puts *[ 'yardoc', yardoc_files, yardoc_options ].flatten.inspect
    system *[ 'yardoc', yardoc_files, yardoc_options ].flatten
  end

end

desc 'Alias for doc:rdoc'
task :doc => [ :'doc:rdoc' ]
