# encoding: utf-8

namespace :validate do

  desc 'Validate the site\'s HTML files'
  task :html do
    # Load site
    site = Nanoc3::Site.new(YAML.load_file(File.join(Dir.getwd, 'config.yaml')))
    if site.nil?
      $stderr.puts 'The current working directory does not seem to be a ' +
                   'valid/complete nanoc site directory; aborting.'
      exit 1
    end

    # Validate
    validator = ::Nanoc3::Extra::Validators::W3C.new(site, :html)
    validator.run
  end

  desc 'Validate the site\'s CSS files'
  task :css do
    # Load site
    site = Nanoc3::Site.new(YAML.load_file(File.join(Dir.getwd, 'config.yaml')))
    if site.nil?
      $stderr.puts 'The current working directory does not seem to be a ' +
                   'valid/complete nanoc site directory; aborting.'
      exit 1
    end

    # Validate
    validator = ::Nanoc3::Extra::Validators::W3C.new(site, :css)
    validator.run
  end

  desc 'Validate all links in the output files'
  task :links do
    # TODO implement
  end

end
