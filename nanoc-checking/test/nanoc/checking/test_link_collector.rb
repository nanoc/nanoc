# frozen_string_literal: true

require 'helper'

module Nanoc
  module Checking
    class LinkCollectorTest < Nanoc::TestCase
      def test_all
        # Create dummy data
        FileUtils.mkdir_p('test dir')
        file_a = File.join(Dir.pwd, 'file-a.html')
        file_b = File.join(Dir.pwd, 'test dir', 'file-b.html')
        File.open(file_a, 'w') do |io|
          io << %(<a href="http://example.com/">A 1</a>)
          io << %(<a href="https://example.com/">A 2</a>)
          io << %(<a href="stuff/">A 3</a>)
          io << %(<a href="stuff with spaces/">A 3b</a>)
          io << %(<a name="href-less-anchor">A 4</a>)
          io << %(<a href="https://example.com/with-fragment#moo">A 5</a>)
        end
        File.open(file_b, 'w') do |io|
          io << %(<a href="mailto:bob@example.com">B 1</a>)
          io << %(<a href="../stuff">B 2</a>)
          io << %(<a href="/stuff">B 2</a>)
        end

        # Create validator
        collector = Nanoc::Checking::LinkCollector.new([file_a, file_b])

        # Test
        hrefs_with_filenames = collector.filenames_per_href
        hrefs = hrefs_with_filenames.keys

        assert_includes hrefs, 'http://example.com/'
        assert_includes hrefs, 'https://example.com/'
        assert_includes hrefs, path_to_file_uri('stuff/', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('stuff with spaces/', Dir.pwd)
        refute_includes hrefs, 'https://example.com/with-fragment#moo'
        assert_includes hrefs, 'https://example.com/with-fragment'
        refute_includes hrefs, nil
        assert_includes hrefs, 'mailto:bob@example.com'
        assert_includes hrefs, 'file:///stuff'
        assert_includes hrefs, path_to_file_uri('stuff', Dir.pwd)
      end

      def test_external
        # Create dummy data
        file_a = File.join(Dir.pwd, 'file-a.html')
        file_b = File.join(Dir.pwd, 'file-b.html')
        File.open(file_a, 'w') do |io|
          io << %(<a href="http://example.com/">A 1</a>)
          io << %(<a href="https://example.com/">A 2</a>)
          io << %(<a href="stuff/"A 3></a>)
        end
        File.open(file_b, 'w') do |io|
          io << %(<a href="mailto:bob@example.com">B 1</a>)
          io << %(<a href="../../../">B 2</a>)
          io << %(<a href="/stuff">B 3</a>)
        end

        # Create validator
        collector = Nanoc::Checking::LinkCollector.new([file_a, file_b], :external)

        # Test
        hrefs_with_filenames = collector.filenames_per_href
        hrefs = hrefs_with_filenames.keys

        assert_includes hrefs, 'http://example.com/'
        assert_includes hrefs, 'https://example.com/'
        refute_includes hrefs, path_to_file_uri('/', Dir.pwd)
        assert_includes hrefs, 'mailto:bob@example.com'
        refute_includes hrefs, path_to_file_uri('/stuff', Dir.pwd)
        refute_includes hrefs, path_to_file_uri('/stuff/', Dir.pwd)
      end

      def test_internal_excludes_external
        # Create dummy data
        output_dir = Dir.pwd
        file_a = File.join(output_dir, 'file-a.html')
        file_b = File.join(output_dir, 'file-b.html')
        File.open(file_a, 'w') do |io|
          io << %(<a href="http://example.com/">A 1</a>)
          io << %(<a href="https://example.com/">A 2</a>)
        end
        File.open(file_b, 'w') do |io|
          io << %(<a href="mailto:bob@example.com">B 1</a>)
          io << %(<a href="https://nanoc.app">B 2</a>)
        end

        # Create validator
        collector = Nanoc::Checking::LinkCollector.new([file_a, file_b], :internal)

        # Test
        hrefs_with_filenames = collector.filenames_per_href
        hrefs = hrefs_with_filenames.keys

        refute_includes hrefs, 'http://example.com/'
        refute_includes hrefs, 'https://example.com/'
        refute_includes hrefs, 'https://nanoc.app'
        refute_includes hrefs, 'mailto:bob@example.com'
      end

      def test_collect_links_from_space_separated_lists
        # The white-space variations in this file’s attributes are intentional
        File.open('file-a.html', 'w') do |io|
          io << %(<img src="image.jpeg" srcset="image-large.jpeg 2000w,	image-medium.jpeg 1000w ,image-small.jpeg 300w">)
          io << %(<source srcset="image-large.webp 2000w,   image-medium.webp 1000w, image-small.webp
300w" type="image/webp">)
          io << %(<a ping="	ping1	ping2		http://example.com/ping3">A 1</a>)
        end

        file_a = File.join(Dir.pwd, 'file-a.html')

        collector = Nanoc::Checking::LinkCollector.new([file_a], :internal)

        # Test
        hrefs_with_filenames = collector.filenames_per_href
        hrefs = hrefs_with_filenames.keys

        assert_includes hrefs, path_to_file_uri('image.jpeg', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('image-large.jpeg', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('image-medium.jpeg', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('image-small.jpeg', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('image-large.webp', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('image-medium.webp', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('image-small.webp', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('ping1', Dir.pwd)
        assert_includes hrefs, path_to_file_uri('ping2', Dir.pwd)
        refute_includes hrefs, 'http://example.com/ping3'
        refute_includes hrefs, nil
        refute_includes hrefs, path_to_file_uri('/', Dir.pwd)
      end

      def test_collects_exotic_links
        file_a = File.join(Dir.pwd, 'file-a.html')
        File.open(file_a, 'w') do |io|
          io << %(<blockquote cite="urn:uuid:6650eb58-86e6-416c-906a-35336e5ac8b2">A 1</blockquote>)
          io << %(<a href="ms-settings:windows-update" ping="https://tracking.nanoc.ws/ping">A 2</a>)
          io << %(<div about="https://nanoc.app/#static-generator">A 3</div>)
          io << %(<base href="https://nanoc.app/all-your-base-are-belong-to-us" />)
        end

        collector = Nanoc::Checking::LinkCollector.new([file_a], :external)

        # Test
        hrefs_with_filenames = collector.filenames_per_href
        hrefs = hrefs_with_filenames.keys

        assert_includes hrefs, 'urn:uuid:6650eb58-86e6-416c-906a-35336e5ac8b2'
        assert_includes hrefs, 'ms-settings:windows-update'
        assert_includes hrefs, 'https://tracking.nanoc.ws/ping'
        refute_includes hrefs, 'https://nanoc.app/#static-generator'
        assert_includes hrefs, 'https://nanoc.app/'
        assert_includes hrefs, 'https://nanoc.app/all-your-base-are-belong-to-us'
      end

      def test_protocol_relative_urls
        File.write('a.html', '<a href="//example.com/broken">broken</a>')

        external_collector =
          Nanoc::Checking::LinkCollector.new(['a.html'], :external)

        internal_collector =
          Nanoc::Checking::LinkCollector.new(['a.html'], :internal)

        hrefs = external_collector.filenames_per_href.keys

        assert_includes hrefs, '//example.com/broken'
        refute_includes hrefs, 'http://example.com/broken'
        refute_includes hrefs, 'file:///example.com/broken'
        refute_includes hrefs, 'file://example.com/broken'

        hrefs = internal_collector.filenames_per_href.keys

        refute_includes hrefs, '//example.com/broken'
        refute_includes hrefs, 'http://example.com/broken'
        refute_includes hrefs, 'file:///example.com/broken'
        refute_includes hrefs, 'file://example.com/broken'
      end
    end
  end
end
