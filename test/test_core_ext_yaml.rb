require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class CoreExtYAMLTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_yaml_load_file_and_clean
    open('test.yaml', 'w') { |io| io.write('created_at: 12/07/04') }

    assert_equal({ :created_at => Time.parse('12/07/04') }, YAML.load_file_and_clean('test.yaml'))

    FileUtils.rm('test.yaml')
  end

end
