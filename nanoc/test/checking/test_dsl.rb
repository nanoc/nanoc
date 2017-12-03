# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::DSLTest < Nanoc::TestCase
  def test_from_file
    with_site do |_site|
      File.open('Checks', 'w') { |io| io.write("check :foo do\n\nend\ndeploy_check :bar\n") }
      dsl = Nanoc::Checking::DSL.from_file('Checks')

      # One new check
      refute Nanoc::Checking::Check.named(:foo).nil?

      # One check marked for deployment
      assert_equal [:bar], dsl.deploy_checks
    end
  end

  def test_has_base_path
    with_site do |_site|
      File.write('stuff.rb', '$greeting = "hello"')
      File.write('Checks', 'require "./stuff"')
      Nanoc::Checking::DSL.from_file('Checks')
      assert_equal 'hello', $greeting
    end
  end

  def test_has_absolute_path
    with_site do |_site|
      File.write('Checks', '$stuff = __FILE__')
      Nanoc::Checking::DSL.from_file('Checks')
      assert($stuff.start_with?('/'))
    end
  end
end
