# encoding: utf-8

require 'test/helper'

class Nanoc3::Extra::AutoCompilerTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_handle_request_with_item_rep
    if_have 'rack' do
      # Create items and reps
      item_reps = [ mock, mock, mock ]
      item_reps[0].stubs(:path).returns('/foo/1/')
      item_reps[0].stubs(:raw_path).returns('out/foo/1/index.html')
      item_reps[1].stubs(:path).returns('/foo/2/')
      item_reps[1].stubs(:raw_path).returns('out/foo/2/index.html')
      item_reps[2].stubs(:path).returns('/bar/')
      item_reps[2].stubs(:raw_path).returns('out/bar/index.html')
      items = [ mock, mock ]
      items[0].stubs(:reps).returns([ item_reps[0], item_reps[1] ])
      items[1].stubs(:reps).returns([ item_reps[2] ])
      item_reps[1].stubs(:item).returns(items[0])

      # Create compiler
      compiler = mock
      compiler.expects(:run).with(item_reps[1].item)

      # Create site
      site = mock
      site.stubs(:items).returns(items)
      site.stubs(:config).returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })
      site.stubs(:compiler).returns(compiler)

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.stubs(:build_reps)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => '/foo/2/') }
    end
  end

  def test_handle_request_with_item_rep_with_index_filename
    if_have 'rack' do
      # Create items and reps
      item_reps = [ mock, mock, mock ]
      item_reps[0].stubs(:path).returns('/foo/1/')
      item_reps[0].stubs(:raw_path).returns('out/foo/1/index.html')
      item_reps[1].stubs(:path).returns('/foo/2/')
      item_reps[1].stubs(:raw_path).returns('out/foo/2/index.html')
      item_reps[2].stubs(:path).returns('/bar/')
      item_reps[2].stubs(:raw_path).returns('out/bar/index.html')
      items = [ mock, mock ]
      items[0].stubs(:reps).returns([ item_reps[0], item_reps[1] ])
      items[1].stubs(:reps).returns([ item_reps[2] ])
      item_reps[1].stubs(:item).returns(items[0])

      # Create compiler
      compiler = mock
      compiler.expects(:run).with(items[0])

      # Create site
      site = mock
      site.stubs(:items).returns(items)
      site.stubs(:config).returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })
      site.stubs(:compiler).returns(compiler)

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.stubs(:build_reps)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => '/foo/2/index.html') }
    end
  end

  def test_handle_request_with_broken_url
    if_have 'rack' do
      # Create items and reps
      item_reps = [ mock, mock, mock ]
      item_reps[0].stubs(:path).returns('/foo/1/')
      item_reps[0].stubs(:raw_path).returns('/foo/1/index.html')
      item_reps[1].stubs(:path).returns('/foo/2/')
      item_reps[1].stubs(:raw_path).returns('/foo/2/index.html')
      item_reps[2].stubs(:path).returns('/bar/')
      item_reps[2].stubs(:raw_path).returns('/bar/index.html')
      items = [ mock, mock ]
      items[0].expects(:reps).returns([ item_reps[0], item_reps[1] ])
      items[1].expects(:reps).returns([ item_reps[2] ])

      # Create site
      site = mock
      site.expects(:items).returns(items)
      site.stubs(:config).returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })

      # Create file server
      file_server = mock
      def file_server.call(env)
        @expected_path_info = '/foo/2'
        @actual_path_info   = env['PATH_INFO']
      end
      def file_server.expected_path_info ; @expected_path_info ; end
      def file_server.actual_path_info   ; @actual_path_info   ; end

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.expects(:file_server).returns(file_server)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => '/foo/2') }

      # Check
      assert_equal(file_server.expected_path_info, file_server.actual_path_info)
    end
  end

  def test_handle_request_with_file
    if_have 'rack' do
      # Create file
      FileUtils.mkdir_p('out')
      File.open('out/somefile.txt', 'w') { |io| io.write('hello') }

      # Create file server
      file_server = mock
      def file_server.call(env)
        @expected_path_info = 'somefile.txt'
        @actual_path_info   = env['PATH_INFO']
      end
      def file_server.expected_path_info ; @expected_path_info ; end
      def file_server.actual_path_info   ; @actual_path_info   ; end

      # Create site
      site = mock
      site.expects(:items).returns([])
      site.expects(:config).returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.expects(:file_server).returns(file_server)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => 'somefile.txt') }

      # Check
      assert_equal(file_server.expected_path_info, file_server.actual_path_info)
    end
  end

  def test_handle_request_with_dir_with_slash_with_index_file
    if_have 'rack' do
      # Create file
      FileUtils.mkdir_p('out/foo/bar')
      File.open('out/foo/bar/index.html', 'w') { |io| io.write('hello') }

      # Create file server
      file_server = mock
      def file_server.call(env)
        @expected_path_info = '/foo/bar/index.html'
        @actual_path_info   = env['PATH_INFO']
      end
      def file_server.expected_path_info ; @expected_path_info ; end
      def file_server.actual_path_info   ; @actual_path_info   ; end

      # Create site
      site = mock
      site.expects(:items).returns([])
      site.expects(:config).at_least_once.returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.expects(:file_server).returns(file_server)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => '/foo/bar/') }

      # Check
      assert_equal(file_server.expected_path_info, file_server.actual_path_info)
    end
  end

  def test_handle_request_with_dir_with_slash_without_index_file
    if_have 'rack' do
      # Create file
      FileUtils.mkdir_p('out/foo/bar')
      File.open('out/foo/bar/someotherfile.txt', 'w') { |io| io.write('hello') }

      # Create file server
      file_server = mock
      def file_server.call(env)
        @expected_path_info = 'foo/bar/'
        @actual_path_info   = env['PATH_INFO']
      end
      def file_server.expected_path_info ; @expected_path_info ; end
      def file_server.actual_path_info   ; @actual_path_info   ; end

      # Create site
      site = mock
      site.expects(:items).returns([])
      site.expects(:config).at_least_once.returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.expects(:file_server).returns(file_server)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => 'foo/bar/') }

      # Check
      assert_equal(file_server.expected_path_info, file_server.actual_path_info)
    end
  end

  def test_handle_request_with_dir_without_slash_with_index_file
    if_have 'rack' do
      # Create file
      FileUtils.mkdir_p('out/foo/bar')
      File.open('out/foo/bar/index.html', 'w') { |io| io.write('hello') }

      # Create file server
      file_server = mock
      def file_server.call(env)
        @expected_path_info = 'foo/bar'
        @actual_path_info   = env['PATH_INFO']
      end
      def file_server.expected_path_info ; @expected_path_info ; end
      def file_server.actual_path_info   ; @actual_path_info   ; end

      # Create site
      site = mock
      site.expects(:items).returns([])
      site.expects(:config).at_least_once.returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.expects(:file_server).returns(file_server)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => 'foo/bar') }

      # Check
      assert_equal(file_server.expected_path_info, file_server.actual_path_info)
    end
  end

  def test_handle_request_with_dir_without_slash_without_index_file
    if_have 'rack' do
      # Create file
      FileUtils.mkdir_p('out/foo/bar')
      File.open('out/foo/bar/someotherfile.txt', 'w') { |io| io.write('hello') }

      # Create file server
      file_server = mock
      def file_server.call(env)
        @expected_path_info = 'foo/bar'
        @actual_path_info   = env['PATH_INFO']
      end
      def file_server.expected_path_info ; @expected_path_info ; end
      def file_server.actual_path_info   ; @actual_path_info   ; end

      # Create site
      site = mock
      site.expects(:items).returns([])
      site.expects(:config).at_least_once.returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.expects(:file_server).returns(file_server)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => 'foo/bar') }

      # Check
      assert_equal(file_server.expected_path_info, file_server.actual_path_info)
    end
  end

  def test_handle_request_with_404
    if_have 'rack' do
      # Create file server
      file_server = mock
      def file_server.call(env)
        @expected_path_info = 'four-oh-four.txt'
        @actual_path_info   = env['PATH_INFO']
      end
      def file_server.expected_path_info ; @expected_path_info ; end
      def file_server.actual_path_info   ; @actual_path_info   ; end

      # Create site
      site = mock
      site.expects(:items).returns([])
      site.expects(:config).at_least_once.returns({ :output_dir => 'out', :index_filenames => [ 'index.html' ] })

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
      autocompiler.stubs(:build_site)
      autocompiler.stubs(:site).returns(site)
      autocompiler.expects(:file_server).returns(file_server)

      # Run
      autocompiler.instance_eval { call('PATH_INFO' => 'four-oh-four.txt') }

      # Check
      assert_equal(file_server.expected_path_info, file_server.actual_path_info)
    end
  end

  def test_mime_type_of
    if_have 'mime/types', 'rack'  do
      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new(nil)

      # Create known test file
      File.open('foo.html', 'w') { |io| io.write('hello') }
      assert_equal(
        'text/html',
        autocompiler.instance_eval { mime_type_of('foo.html', 'huh') }
      )

      # Create unknown test file
      File.open('foo', 'w') { |io| io.write('hello') }
      assert_equal(
        'huh',
        autocompiler.instance_eval { mime_type_of('foo', 'huh') }
      )
    end
  end

  def test_serve_with_working_item
    if_have 'mime/types', 'rack' do
      # Create site
      Nanoc3::CLI::Base.new.run([ 'create_site', 'bar' ])

      FileUtils.cd('bar') do
        # Create item
        File.open('content/index.html', 'w') do |io|
          io.write "Moo!"
        end

        # Create output file
        File.open('output/index.html', 'w') do |io|
          io.write "Compiled moo!"
        end

        # Create site
        site = Nanoc3::Site.new('.')
        site.compiler.expects(:run).with(site.items[0])

        # Create autocompiler
        autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
        autocompiler.stubs(:build_site)
        autocompiler.stubs(:site).returns(site)

        # Serve
        status, headers, body = autocompiler.instance_eval { call('PATH_INFO' => '/') }

        # Check response
        assert_equal(200, status)
        assert_equal('text/html', headers['Content-Type'])
        body.each do |b|
          assert_equal "Compiled moo!", b
        end
      end
    end
  end

  def test_serve_with_broken_item
    if_have 'mime/types', 'rack' do
      # Create site
      Nanoc3::CLI::Base.new.run([ 'create_site', 'bar' ])

      FileUtils.cd('bar') do
        # Create item
        File.open('content/whatever.html', 'w') do |io|
          io.write "Whatever!"
        end

        # Create site
        site = Nanoc3::Site.new('.')
        site.compiler.expects(:run).raises(RuntimeError, 'aah! fail!')

        # Create autocompiler
        autocompiler = Nanoc3::Extra::AutoCompiler.new('.')
        autocompiler.stubs(:build_site)
        autocompiler.stubs(:site).returns(site)

        # Serve
        assert_raises(RuntimeError) do
          autocompiler.instance_eval { call('PATH_INFO' => '/whatever/') }
        end
      end
    end
  end

  def test_reload_config_file_before_each_request
    # Create site
    Nanoc3::CLI::Base.new.run([ 'create_site', 'foo' ])

    FileUtils.cd('foo') do
      # Create item that outputs config elements
      File.open('content/index.html', 'w') do |io|
        io.write "The Grand Value of Configuration is <%= @config[:value] %>!"
      end

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new('.')

      # Set config to 1st value
      File.open('config.yaml', 'w') do |io|
        io.write "value: Foo"
      end
      File.utime(Time.now+5, Time.now+5, 'config.yaml')

      # Check
      status, headers, body = autocompiler.call('PATH_INFO' => '/')
      body.each do |b|
        assert_match /The Grand Value of Configuration is Foo!/, b
      end

      # Set config to 2nd value
      File.open('config.yaml', 'w') do |io|
        io.write "value: Bar"
      end
      File.utime(Time.now+5, Time.now+5, 'config.yaml')

      # Check
      status, headers, body = autocompiler.call('PATH_INFO' => '/')
      body.each do |b|
        assert_match /The Grand Value of Configuration is Bar!/, b
      end
    end
  end

  def test_call_with_uri_encoded_path
    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new('.')

    # Mock dependencies
    site = mock
    site.stubs(:config).returns({ :output_dir => 'output/' })
    site.stubs(:items).returns([])
    autocompiler.stubs(:build_site)
    autocompiler.stubs(:site).returns(site)

    # Test
    result = autocompiler.call('PATH_INFO' => '/%73oftware')
    assert_equal 404, result[0]
    assert_match "File not found: /software\n", result[2][0]
  end

end
