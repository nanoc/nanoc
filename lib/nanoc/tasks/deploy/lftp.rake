# encoding: utf-8

require 'nanoc/cli'

# Inspired by https://github.com/nanoc/nanoc/blob/9b58936e31c00aeb7589b6abb88cf4f2ed73eb5b/lib/nanoc/tasks/deploy/rsync.rake
# Frankly, I have no idea what this does - added for symmetry reasons (see rsync.rake) only.
namespace :deploy do

  desc 'Upload the compiled site using lftp'
  task :lftp do
    dry_run     = !!ENV['dry_run']
    config_name = ENV['config'] || :default

    cmd = [ 'deploy', '-t', config_name ]
    cmd << '-n' if dry_run

    Nanoc::CLI.run cmd
  end

end