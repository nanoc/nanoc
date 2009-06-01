# encoding: utf-8

desc 'Fetch all dependencies for nanoc3'
task :fetch_dependencies do
  # Get Cri
  unless File.directory?('vendor/cri')
    puts "=== Fetching Cri..."
    FileUtils.mkdir_p('vendor')
    system('hg', 'clone', 'http://projects.stoneship.org/hg/shared/cri', 'vendor/cri')
    puts '=== Fetching Cri: done.'
  end
end
