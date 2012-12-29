# encoding: utf-8

class Nanoc::Extra::Checking::RunnerTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run
    with_site do |site|
      File.open('output/blah', 'w') { |io| io.write('I am stale! Haha!') }
      runner = Nanoc::Extra::Checking::Runner.new(site)
      runner.run_specific(%w( stale ))
    end
  end

end
