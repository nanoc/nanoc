# encoding: utf-8

namespace :validate do

  desc 'Validate the site’s HTML files'.make_compatible_with_env
  task :html do
    Nanoc::CLI.run %w( validate_html )
  end

  desc 'Validate the site’s CSS files'.make_compatible_with_env
  task :css do
    Nanoc::CLI.run %w( validate_css )
  end

  namespace :links do

    desc 'Validate the site’s internal links'.make_compatible_with_env
    task :internal do
      Nanoc::CLI.run %w( validate_links --internal )
    end

    desc 'Validate the site’s external links'.make_compatible_with_env
    task :external do
      Nanoc::CLI.run %w( validate_links --external )
    end

  end

  desc 'Validate the site’s internal and external links'.make_compatible_with_env
  task :links do
    Nanoc::CLI.run %w( validate_links )
  end

end
