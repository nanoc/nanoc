# encoding: utf-8

class Nanoc::Extra::Checking::CheckerTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_max_severity
    with_site do |site|
      checker = Nanoc::Extra::Checking::Checker.new(site)
      assert_equal :ok, checker.max_severity
      checker.add_issue('foo', :severity => :ok)
      assert_equal :ok, checker.max_severity
      checker.add_issue('bar', :severity => :error)
      assert_equal :error, checker.max_severity
    end
  end

  def test_output_filenames
    with_site do |site|
      checker = Nanoc::Extra::Checking::Checker.new(site)
      assert checker.output_filenames.empty?
      File.open('output/foo.html', 'w') { |io| io.write 'hello' }
      assert_equal [ 'output/foo.html' ], checker.output_filenames
    end
  end

end
