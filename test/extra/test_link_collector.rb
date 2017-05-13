# frozen_string_literal: true

require 'helper'

class Nanoc::Extra::LinkCollectorTest < Nanoc::TestCase
  def test_all
    # Create dummy data
    File.open('file-a.html', 'w') do |io|
      io << %(<a href="http://example.com/">A 1</a>
)
      io << %(<a href="https://example.com/">A 2</a>
)
      io << %(<a href="stuff/"A 3></a>
)
      io << %(<a name="href-less-anchor">A 4</a>)
      io << %(<a href="https://example.com/with-fragment#moo">A 5</a>
)
    end
    File.open('file-b.html', 'w') do |io|
      io << %(<a href="mailto:bob@example.com">B 1</a>
)
      io << %(<a href="../stuff">B 2</a>
)
      io << %(<a href="/stuff">B 3</a>
)
    end

    # Create validator
    collector = Nanoc::Extra::LinkCollector.new(%w[file-a.html file-b.html])

    # Test
    hrefs_with_filenames = collector.filenames_per_href
    hrefs = hrefs_with_filenames.keys
    assert_includes hrefs, 'http://example.com/'
    assert_includes hrefs, 'https://example.com/'
    assert_includes hrefs, 'stuff/'
    refute_includes hrefs, nil
    assert_includes hrefs, 'mailto:bob@example.com'
    assert_includes hrefs, '../stuff'
    assert_includes hrefs, '/stuff'
    refute_includes hrefs, 'https://example.com/with-fragment#moo'
    assert_includes hrefs, 'https://example.com/with-fragment'
  end

  def test_external
    # Create dummy data
    File.open('file-a.html', 'w') do |io|
      io << %(<a href="http://example.com/">A 1</a>
)
      io << %(<a href="https://example.com/">A 2</a>
)
      io << %(<a href="stuff/"A 3></a>
)
    end
    File.open('file-b.html', 'w') do |io|
      io << %(<a href="mailto:bob@example.com">B 1</a>
)
      io << %(<a href="../stuff">B 2</a>
)
      io << %(<a href="/stuff">B 3</a>
)
    end

    # Create validator
    collector = Nanoc::Extra::LinkCollector.new(%w[file-a.html file-b.html], :external)

    # Test
    hrefs_with_filenames = collector.filenames_per_href
    hrefs = hrefs_with_filenames.keys
    assert_includes hrefs, 'http://example.com/'
    assert_includes hrefs, 'https://example.com/'
    refute_includes hrefs, 'stuff/'
    assert_includes hrefs, 'mailto:bob@example.com'
    refute_includes hrefs, '../stuff'
    refute_includes hrefs, '/stuff'
  end

  def test_internal
    # Create dummy data
    File.open('file-a.html', 'w') do |io|
      io << %(<a href="http://example.com/">A 1</a>
)
      io << %(<a href="https://example.com/">A 2</a>
)
      io << %(<a href="stuff/"A 3></a>
)
    end
    File.open('file-b.html', 'w') do |io|
      io << %(<a href="mailto:bob@example.com">B 1</a>
)
      io << %(<a href="../stuff">B 2</a>
)
      io << %(<a href="/stuff">B 3</a>
)
    end

    # Create validator
    collector = Nanoc::Extra::LinkCollector.new(%w[file-a.html file-b.html], :internal)

    # Test
    hrefs_with_filenames = collector.filenames_per_href
    hrefs = hrefs_with_filenames.keys
    refute_includes hrefs, 'http://example.com/'
    refute_includes hrefs, 'https://example.com/'
    assert_includes hrefs, 'stuff/'
    refute_includes hrefs, 'mailto:bob@example.com'
    assert_includes hrefs, '../stuff'
    assert_includes hrefs, '/stuff'
  end
end
