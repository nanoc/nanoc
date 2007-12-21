require File.dirname(__FILE__) + '/../lib/nanoc.rb'

def with_site_fixture(a_fixture)
  in_dir(['test', 'fixtures', a_fixture]) do
    yield(Nanoc::Site.from_cwd)
  end
end

def test_require(x)
  require x
rescue LoadError
  $stderr.print "[ skipped -- requiring #{x} failed ]"
  return
end

def global_setup
  # Go quiet
  $log_level = :off unless ENV['QUIET'] == 'false'

  # Create tmp directory
  FileManager.create_dir 'tmp'
end

def global_teardown
  # Remove tmp directory
  FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')

  # Remove output
  Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure(f) if File.exist?(f)}
end
