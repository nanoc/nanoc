desc 'Fetch all dependencies for nanoc3'
task :fetch_dependencies do
  # Get Cri
  unless File.directory?('vendor/cri')
    puts "=== Fetching Cri..."
    system('hg', 'clone', 'http://projects.stoneship.org/hg/shared/cri', 'vendor/cri')
    puts '=== Fetching Cri: done.'
  end
end
