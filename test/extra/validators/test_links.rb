# encoding: utf-8

class Nanoc::Extra::Validators::LinksTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_is_external_href?
    # Create validator
    validator = Nanoc::Extra::Validators::Links.new(nil, nil)

    # Test
    assert  validator.send(:is_external_href?, 'http://example.com/')
    assert  validator.send(:is_external_href?, 'https://example.com/')
    assert  validator.send(:is_external_href?, 'mailto:bob@example.com')
    assert !validator.send(:is_external_href?, '../stuff')
    assert !validator.send(:is_external_href?, '/stuff')
  end

  def test_is_valid_internal_href?
    # Create files
    FileUtils.mkdir_p('output')
    FileUtils.mkdir_p('output/stuff')
    File.open('output/origin',     'w') { |io| io.write('hi') }
    File.open('output/foo',        'w') { |io| io.write('hi') }
    File.open('output/stuff/blah', 'w') { |io| io.write('hi') }

    # Create validator
    validator = Nanoc::Extra::Validators::Links.new('output', [ 'index.html' ])

    # Test
    assert validator.send(:is_valid_internal_href?, 'foo',         'output/origin')
    assert validator.send(:is_valid_internal_href?, 'origin',      'output/origin')
    assert validator.send(:is_valid_internal_href?, 'stuff/blah',  'output/origin')
    assert validator.send(:is_valid_internal_href?, '/foo',        'output/origin')
    assert validator.send(:is_valid_internal_href?, '/origin',     'output/origin')
    assert validator.send(:is_valid_internal_href?, '/stuff/blah', 'output/origin')
  end

  def test_is_valid_external_href?
    # Create validator
    validator = Nanoc::Extra::Validators::Links.new('output', [ 'index.html' ])
    validator.stubs(:fetch_http_status_for).returns(200)

    # Test
    assert validator.send(:is_valid_external_href?, 'http://example.com/')
    assert validator.send(:is_valid_external_href?, 'https://example.com/')
    assert validator.send(:is_valid_external_href?, 'foo://example.com/')
    refute validator.send(:is_valid_external_href?, 'http://example.com/">')
  end

  def test_fetch_http_status_for
    # Create validator
    validator = Nanoc::Extra::Validators::Links.new('output', [ 'index.html' ])

    # Test
    assert validator.send(:fetch_http_status_for, URI.parse('http://heise.de/'), 200)
    assert validator.send(:fetch_http_status_for, URI.parse('https://www.google.com/'), 200)
    assert validator.send(:fetch_http_status_for, URI.parse('https://google.com/'), 200)
    assert validator.send(:fetch_http_status_for, URI.parse('http://google.com/foo/bar'), 404)
  end

end
