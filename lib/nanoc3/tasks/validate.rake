# encoding: utf-8

namespace :validate do

  desc 'Validate the site’s HTML files'.make_compatible_with_env
  task :html do
    # Get output directory
    site = Nanoc3::Site.new('.')
    if site.nil?
      $stderr.puts 'The current working directory does not seem to be a ' +
                   'valid/complete nanoc site directory; aborting.'
      exit 1
    end
    dir = site.config[:output_dir]

    # Validate
    validator = ::Nanoc3::Extra::Validators::W3C.new(dir, [ :html ])
    validator.run
  end

  desc 'Validate the site’s CSS files'.make_compatible_with_env
  task :css do
    # Get output directory
    site = Nanoc3::Site.new('.')
    if site.nil?
      $stderr.puts 'The current working directory does not seem to be a ' +
                   'valid/complete nanoc site directory; aborting.'
      exit 1
    end
    dir = site.config[:output_dir]

    # Validate
    validator = ::Nanoc3::Extra::Validators::W3C.new(dir, [ :css ])
    validator.run
  end

  namespace :links do

    desc 'Validate the site’s internal links'.make_compatible_with_env
    task :internal do
      # Get output directory
      site = Nanoc3::Site.new('.')
      if site.nil?
        $stderr.puts 'The current working directory does not seem to be a ' +
                     'valid/complete nanoc site directory; aborting.'
        exit 1
      end
      dir             = site.config[:output_dir]
      index_filenames = site.config[:index_filenames]

      # Validate
      validator = ::Nanoc3::Extra::Validators::Links.new(dir, index_filenames, :internal => true)
      validator.run
    end

    desc 'Validate the site’s internal links'.make_compatible_with_env
    task :external do
      # Get output directory
      site = Nanoc3::Site.new('.')
      if site.nil?
        $stderr.puts 'The current working directory does not seem to be a ' +
                     'valid/complete nanoc site directory; aborting.'
        exit 1
      end
      dir             = site.config[:output_dir]
      index_filenames = site.config[:index_filenames]

      # Validate
      validator = ::Nanoc3::Extra::Validators::Links.new(dir, index_filenames, :external => true)
      validator.run
    end

  end

  desc 'Validate the site’s internal and external links'.make_compatible_with_env
  task :links do
    # Get output directory
    site = Nanoc3::Site.new('.')
    if site.nil?
      $stderr.puts 'The current working directory does not seem to be a ' +
                   'valid/complete nanoc site directory; aborting.'
      exit 1
    end
    dir             = site.config[:output_dir]
    index_filenames = site.config[:index_filenames]

    # Validate
    validator = ::Nanoc3::Extra::Validators::Links.new(dir, index_filenames, :internal => true, :external => true)
    validator.run
  end

end
