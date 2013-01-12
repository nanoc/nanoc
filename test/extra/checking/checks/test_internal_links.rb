# encoding: utf-8

class Nanoc::Extra::Checking::Checks::InternalLinksTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      FileUtils.mkdir_p('output/stuff')
      File.open('output/foo.txt',  'w') { |io| io.write('<a href="/broken">broken</a>') }
      File.open('output/bar.html', 'w') { |io| io.write('<a href="/foo.txt">not broken</a>') }

      # Create check
      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)
      check.run

      # Test
      assert check.issues.empty?
    end
  end

  def test_valid?
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      FileUtils.mkdir_p('output/stuff')
      File.open('output/origin',     'w') { |io| io.write('hi') }
      File.open('output/foo',        'w') { |io| io.write('hi') }
      File.open('output/stuff/blah', 'w') { |io| io.write('hi') }

      # Create check
      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)

      # Test
      assert check.send(:valid?, 'foo',         'output/origin')
      assert check.send(:valid?, 'origin',      'output/origin')
      assert check.send(:valid?, 'stuff/blah',  'output/origin')
      assert check.send(:valid?, '/foo',        'output/origin')
      assert check.send(:valid?, '/origin',     'output/origin')
      assert check.send(:valid?, '/stuff/blah', 'output/origin')
    end
  end

end
