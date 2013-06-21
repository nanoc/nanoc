# encoding: utf-8

class Nanoc::Extra::Checking::RunnerTest < Nanoc::TestCase

  def test_run_specific
    in_site do
      File.write('output/blah', 'I am stale! Haha!')
      runner = Nanoc::Extra::Checking::Runner.new(site_here)
      runner.run_specific(%w( stale ))
    end
  end

  def test_run_specific_custom
    in_site do
      File.open('Checks', 'w') do |io|
        io.write('check :my_foo_check do ; puts "I AM FOO!" ; end')
      end

      runner = Nanoc::Extra::Checking::Runner.new(site_here)
      ios = capturing_stdio do
        runner.run_specific(%w( my_foo_check ))
      end

      assert ios[:stdout].include?('I AM FOO!')
    end
  end

  def test_list_checks
    in_site do
      File.open('Checks', 'w') do |io|
        io.write('check :my_foo_check do ; end')
      end

      runner = Nanoc::Extra::Checking::Runner.new(site_here)
      ios = capturing_stdio do
        runner.list_checks
      end

      assert ios[:stdout].include?('my_foo_check')
      assert ios[:stdout].include?('internal_links')
      assert ios[:stderr].empty?
    end
  end

end
