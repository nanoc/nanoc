require 'test/unit'

require File.join(File.dirname(__FILE__), '..', 'lib', 'nanoc.rb')
require File.join(File.dirname(__FILE__), '..', 'lib', 'nanoc', 'cli', 'cli.rb')

def with_site_fixture(a_fixture)
  in_dir(['test', 'fixtures', a_fixture]) do
    yield(Nanoc::Site.new(YAML.load_file('config.yaml')))
  end
end

def create_site(name)
  Nanoc::CLI::Base.new.run(['create_site', name])
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
  $log_level = :off unless ENV['QUIET'] == 'false'

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
