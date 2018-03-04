# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::DSLTest < Nanoc::TestCase
  def test_from_file
    with_site do |_site|
      File.open('Checks', 'w') { |io| io.write("check :foo do\n\nend\ndeploy_check :bar\n") }
      enabled_checks = []
      Nanoc::Checking::DSL.from_file('Checks', enabled_checks: enabled_checks)

      refute Nanoc::Checking::Check.named(:foo).nil?

      assert_equal [:bar], enabled_checks
    end
  end

  def test_has_base_path
    with_site do |_site|
      File.write('stuff.rb', '$greeting = "hello"')
      File.write('Checks', 'require "./stuff"')
      Nanoc::Checking::DSL.from_file('Checks', enabled_checks: [])
      assert_equal 'hello', $greeting
    end
  end

  def test_has_absolute_path
    with_site do |_site|
      File.write('Checks', '$stuff = __FILE__')
      Nanoc::Checking::DSL.from_file('Checks', enabled_checks: [])
      assert(Pathname.new($stuff).absolute?)
    end
  end
end
