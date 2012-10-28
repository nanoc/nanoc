# encoding: utf-8

class Nanoc::Extra::Checking::Checkers::HTMLTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run_ok
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { | io| io.write('<!DOCTYPE html><html><head><title>Hello</title></head><body><h1>Hi!</h1></body>') }
      File.open('output/style.css', 'w') { | io| io.write('h1 { coxlor: rxed; }') }

      # Run checker
      checker = Nanoc::Extra::Checking::Checkers::HTML.new(site)
      checker.run

      # Check
      assert checker.issues.empty?
    end
  end

  def test_run_error
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { | io| io.write('<h2>Hi!</h1>') }
      File.open('output/style.css', 'w') { | io| io.write('h1 { coxlor: rxed; }') }

      # Run checker
      checker = Nanoc::Extra::Checking::Checkers::HTML.new(site)
      checker.run

      # Check
      refute checker.issues.empty?
    end
  end

end

