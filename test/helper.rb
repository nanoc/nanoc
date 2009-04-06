# Add vendor to load path
[ 'mocha', 'mime-types' ].each do |e|
  path = File.join(File.dirname(__FILE__), '..', 'vendor', e, 'lib')
  next unless File.directory?(path)
  $LOAD_PATH.unshift(File.expand_path(path))
end

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

# Load nanoc
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'nanoc3'
require 'nanoc3/cli'
require 'nanoc3/tasks'

# Load miscellaneous requirements
require 'stringio'

module Nanoc3::TestHelpers

  def with_temp_site(data_source='filesystem')
    in_dir %w{ tmp } do
      # Create site
      create_site('site', data_source)

      in_dir %w{ site } do
        # Load site
        site = Nanoc3::Site.new(YAML.load_file('config.yaml'))

        # Done
        yield site
      end
    end
  end

  # Convenience function for cd'ing in and out of a directory
  def in_dir(path)
    FileUtils.cd(File.join([ path ].flatten))
    yield
  ensure
    FileUtils.cd(File.join([ path ].flatten.map { |n| '..' }))
  end

  def create_site(name, data_source='filesystem')
    Nanoc3::CLI::Base.new.run(['create_site', name, '-d', data_source])
  end

  def create_layout(name)
    Nanoc3::CLI::Base.new.run(['create_layout', name])
  end

  def create_page(name)
    Nanoc3::CLI::Base.new.run(['create_page', name])
  end

  def if_have(x)
    require x
    yield
  rescue LoadError
    skip "requiring #{x} failed"
  end

  def setup
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

  def teardown
    # Remove tmp directory
    FileUtils.rm_rf 'tmp' if File.exist?('tmp')

    # Go unquiet
    unless ENV['QUIET'] == 'false'
      $stdout = $stdout_real
      $stderr = $stderr_real
    end
  end

end
