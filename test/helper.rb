# Try getting RubyGems
begin ; require 'rubygems' ; rescue LoadError ; end

# Load unit testing stuff
begin
  require 'minitest/unit'
  require 'minitest/spec'
  require 'minitest/mock'
  require 'mocha'
rescue => e
  $stderr.puts "To run the nanoc unit tests, you need minitest and mocha."
  raise e
end
require 'stringio'

# Load nanoc
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'nanoc'
require 'nanoc/cli'

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
  begin
    skip "requiring #{x} failed"
  rescue NoMethodError
    $stderr_real.print "[ skipped -- requiring #{x} failed ]"
  end
end

def global_setup
  # Clean up
  GC.start

  # Go quiet
  $stdout_real = $stdout
  $stderr_real = $stderr
  unless ENV['QUIET'] == 'false'
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  # Create tmp directory
  FileUtils.mkdir_p('tmp')
end

def global_teardown
  # Remove tmp directory
  FileUtils.rm_rf 'tmp' if File.exist?('tmp')

  # Go unquiet
  unless ENV['QUIET'] == 'false'
    $stdout = $stdout_real
    $stderr = $stderr_real
  end

  # Remove output
  Dir[File.join('test', 'fixtures', '*', 'output', '*')].each do |f|
    FileUtils.rm_rf(f) if File.exist?(f)
  end
end
