# encoding: utf-8

require 'nanoc/cli'

namespace :deploy do

  desc 'Upload the compiled site using rsync'
  task :rsync do
    dry_run     = !!ENV['dry_run']
    config_name = ENV['config'] || :default

    cmd = [ 'deploy', '-t', config_name ]
    cmd << '-n' if dry_run

    Nanoc::CLI.run cmd
  end

end
