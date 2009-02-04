desc 'Fetch all dependencies for nanoc'
task :fetch_dependencies do
  # Get Cri
  puts "=== Fetching Cri..."
  if File.directory?('vendor/cri')
    warn "Cri already exists in vendor/cri; not replacing it"
  else
    system('hg', 'clone', 'http://projects.stoneship.org/hg/shared/cri', 'vendor/cri')
  end
  puts '=== Fetching Cri: done.'
end
