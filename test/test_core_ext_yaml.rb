require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CoreExtYAMLTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_yaml_load_file_and_clean
    open('test.yaml', 'w') { |io| io.write('created_at: 12/07/04') }

    assert_equal({ :created_at => Time.parse('12/07/04') }, YAML.load_file_and_clean('test.yaml'))

    FileUtils.rm('test.yaml')
  end

end
