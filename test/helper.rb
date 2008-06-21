# Try getting RubyGems
begin ; require 'rubygems' ; rescue LoadError ; end

# Load unit testing stuff
require 'test/unit'
require 'mocha'

# Load nanoc
require File.join(File.dirname(__FILE__), '..', 'lib', 'nanoc.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'nanoc', 'cli', 'cli.rb')

def with_site_fixture(a_fixture)
  in_dir(['test', 'fixtures', a_fixture]) do
    yield(Nanoc::Site.new(YAML.load_file('config.yaml')))
  end
end

def with_temp_site(data_source='filesystem')
  in_dir %w{ tmp } do
    # Create site
    create_site('site', data_source)

    in_dir %w{ site } do
      # Load site
      site = Nanoc::Site.new(YAML.load_file('config.yaml'))
      site.load_data

      # Done
      yield site
    end
  end
end

# Convenience function for cd'ing in and out of a directory
def in_dir(path)
  FileUtils.cd(File.join(path))
  yield
ensure
  FileUtils.cd(File.join(path.map { |n| '..' }))
end

def create_site(name, data_source='filesystem')
  Nanoc::CLI::Base.new.run(['create_site', name, '-d', data_source])
end

def create_layout(name)
  Nanoc::CLI::Base.new.run(['create_layout', name])
end

def create_page(name)
  Nanoc::CLI::Base.new.run(['create_page', name])
end

def create_template(name)
  Nanoc::CLI::Base.new.run(['create_template', name])
end

def if_have(x)
  require x
  yield
rescue LoadError
  $stderr.print "[ skipped -- requiring #{x} failed ]"
end

def global_setup
  # Go quiet
  unless ENV['QUIET'] == 'false'
    $log_level = :off
    Nanoc::CLI::Logger.instance.level = :off
  end

  # Create tmp directory
  FileUtils.mkdir_p('tmp')
end

def global_teardown
  # Remove tmp directory
  FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')

  # Remove output
  Dir[File.join('test', 'fixtures', '*', 'output', '*')].each do |f|
    FileUtils.remove_entry_secure(f) if File.exist?(f)
  end
end
