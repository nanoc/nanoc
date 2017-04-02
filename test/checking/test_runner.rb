require 'helper'

class Nanoc::Checking::RunnerTest < Nanoc::TestCase
  def test_run_specific
    with_site do |site|
      File.open('output/blah', 'w') { |io| io.write('I am stale! Haha!') }
      runner = Nanoc::Checking::Runner.new(site)
      runner.run_specific(%w[stale])
    end
  end

  def test_run_specific_custom
    with_site do |site|
      File.open('Checks', 'w') do |io|
        io.write('check :my_foo_check do ; puts "I AM FOO!" ; end')
      end

      runner = Nanoc::Checking::Runner.new(site)
      ios = capturing_stdio do
        runner.run_specific(%w[my_foo_check])
      end

      assert ios[:stdout].include?('I AM FOO!')
    end
  end

  def test_list_checks
    with_site do |site|
      File.open('Checks', 'w') do |io|
        io.write('check :my_foo_check do ; end')
      end

      runner = Nanoc::Checking::Runner.new(site)
      ios = capturing_stdio do
        runner.list_checks
      end

      assert ios[:stdout].include?('my_foo_check')
      assert ios[:stdout].include?('internal_links')
      assert ios[:stderr].empty?
    end
  end
end
