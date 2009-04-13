require 'test/helper'

class Nanoc3::Extra::AutoCompilerTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_start
    # TODO implement
  end

  def test_preferred_handler
    # Create autocompiler
    aco = Nanoc3::Extra::AutoCompiler.new(nil)

    # Check preferred handler
    handlers = sequence('handlers')
    aco.expects(:handler_named).with(:thin).returns(nil).in_sequence(handlers)
    aco.expects(:handler_named).with(:mongrel).returns(':D').in_sequence(handlers)
    assert_equal(':D', aco.instance_eval { preferred_handler })
  end

  def test_handler_named
    if_have 'rack' do
      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new(nil)

      # Check handler without requirements
      assert_equal(
        Rack::Handler::WEBrick,
        autocompiler.instance_eval { handler_named(:webrick) }
      )
    end
  end

  def test_handle_request_with_page_rep
    # Create pages and reps
    page_reps = [ mock, mock, mock ]
    page_reps[0].stubs(:path).returns('/foo/1/')
    page_reps[1].stubs(:path).returns('/foo/2/')
    page_reps[2].stubs(:path).returns('/bar/')
    pages = [ mock, mock ]
    pages[0].stubs(:reps).returns([ page_reps[0], page_reps[1] ])
    pages[1].stubs(:reps).returns([ page_reps[2] ])

    # Create site
    site = mock
    site.stubs(:load_data).with(true)
    site.stubs(:pages).returns(pages)
    site.stubs(:assets).returns([])
    site.stubs(:config).returns({ :output_dir => 'output/', :index_filenames => [ 'index.html' ] })

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_rep).with(page_reps[1])

    # Run
    autocompiler.instance_eval { handle_request('/foo/2/') }
  end

  def test_handle_request_with_asset_rep
    # Create assets and reps
    asset_reps = [ mock, mock, mock ]
    asset_reps[0].stubs(:path).returns('/assets/foo/1/')
    asset_reps[1].stubs(:path).returns('/assets/foo/2/')
    asset_reps[2].stubs(:path).returns('/assets/bar/')
    assets = [ mock, mock ]
    assets[0].stubs(:reps).returns([ asset_reps[0], asset_reps[1] ])
    assets[1].stubs(:reps).returns([ asset_reps[2] ])

    # Create site
    site = mock
    site.stubs(:load_data).with(true)
    site.stubs(:pages).returns([])
    site.stubs(:assets).returns(assets)
    site.stubs(:config).returns({ :output_dir => 'output/', :index_filenames => [ 'index.html' ] })

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_rep).with(asset_reps[1])

    # Run
    autocompiler.instance_eval { handle_request('/assets/foo/2/') }
  end

  def test_handle_request_with_broken_url
    # Create pages and reps
    page_reps = [ mock, mock, mock ]
    page_reps[0].expects(:path).at_most_once.returns('/foo/1/')
    page_reps[1].expects(:path).returns('/foo/2/')
    page_reps[2].expects(:path).at_most_once.returns('/bar/')
    pages = [ mock, mock ]
    pages[0].expects(:reps).returns([ page_reps[0], page_reps[1] ])
    pages[1].expects(:reps).returns([ page_reps[2] ])

    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns(pages)
    site.expects(:assets).returns([])
    site.expects(:config).returns({ :output_dir => 'output/', :index_filenames => [ 'index.html' ] })

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_404).with('/foo/2')

    # Run
    autocompiler.instance_eval { handle_request('/foo/2') }
  end

  def test_handle_request_with_file
    # Create pages and reps
    page_reps = [ mock, mock, mock ]
    page_reps[0].expects(:path).returns('/foo/1/')
    page_reps[1].expects(:path).returns('/foo/2/')
    page_reps[2].expects(:path).returns('/bar/')
    pages = [ mock, mock ]
    pages[0].expects(:reps).returns([ page_reps[0], page_reps[1] ])
    pages[1].expects(:reps).returns([ page_reps[2] ])

    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns(pages)
    site.expects(:assets).returns([])
    site.expects(:config).at_least_once.returns({ :output_dir => 'out/', :index_filenames => [ 'index.html' ] })

    # Create file
    FileUtils.mkdir_p('out')
    File.open('out/somefile.txt', 'w') { |io| }

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_file).with('out/somefile.txt')

    # Run
    autocompiler.instance_eval { handle_request('somefile.txt') }
  end

  def test_handle_request_with_dir_with_slash_with_index_file
    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:config).at_least_once.returns({ :output_dir => 'out/', :index_filenames => [ 'index.html' ] })

    # Create file
    FileUtils.mkdir_p('out/foo/bar')
    File.open('out/foo/bar/index.html', 'w') { |io| }

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_file).with('out/foo/bar/index.html')

    # Run
    autocompiler.instance_eval { handle_request('foo/bar/') }
  end

  def test_handle_request_with_dir_with_slash_without_index_file
    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:config).at_least_once.returns({ :output_dir => 'out/', :index_filenames => [ 'index.html' ] })

    # Create file
    FileUtils.mkdir_p('out/foo/bar')
    File.open('out/foo/bar/someotherfile.txt', 'w') { |io| }

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_404).with('foo/bar/')

    # Run
    autocompiler.instance_eval { handle_request('foo/bar/') }
  end

  def test_handle_request_with_dir_without_slash_with_index_file
    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:config).at_least_once.returns({ :output_dir => 'out/', :index_filenames => [ 'index.html' ] })

    # Create file
    FileUtils.mkdir_p('out/foo/bar')
    File.open('out/foo/bar/index.html', 'w') { |io| }

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_404).with('foo/bar')

    # Run
    autocompiler.instance_eval { handle_request('foo/bar') }
  end

  def test_handle_request_with_dir_without_slash_without_index_file
    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:config).at_least_once.returns({ :output_dir => 'out/', :index_filenames => [ 'index.html' ] })

    # Create file
    FileUtils.mkdir_p('out/foo/bar')
    File.open('out/foo/bar/someotherfile.txt', 'w') { |io| }

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_404).with('foo/bar')

    # Run
    autocompiler.instance_eval { handle_request('foo/bar') }
  end

  def test_handle_request_with_404
    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:config).at_least_once.returns({ :output_dir => 'out/', :index_filenames => [ 'index.html' ] })

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)
    autocompiler.expects(:serve_404).with('someotherfile.txt')

    # Run
    autocompiler.instance_eval { handle_request('someotherfile.txt') }
  end

  def test_h
    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(nil)

    # Check HTML escaping
    assert_equal(
      '&lt; &amp; &gt; \' &quot;',
      autocompiler.instance_eval { h('< & > \' "') }
    )
  end

  def test_mime_type_of
    if_have('mime/types') do
      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new(nil)

      # Create known test file
      File.open('foo.html', 'w') { |io| }
      assert_equal(
        'text/html',
        autocompiler.instance_eval { mime_type_of('foo.html', 'huh') }
      )

      # Create unknown test file
      File.open('foo', 'w') { |io| }
      assert_equal(
        'huh',
        autocompiler.instance_eval { mime_type_of('foo', 'huh') }
      )
    end
  end

  def test_serve_400
    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(nil)

    # Fill response for 404
    response = autocompiler.instance_eval { serve_404('/foo/bar/baz/') }

    # Check response
    assert_equal(404,                   response[0])
    assert_equal('text/html',           response[1]['Content-Type'])
    assert_match(/404 File Not Found/,  response[2][0])
  end

  def test_serve_500
    # Create site
    stack = []
    compiler = mock
    compiler.expects(:stack).returns(stack)
    site = mock
    site.expects(:compiler).returns(compiler)

    # Create autocompiler
    autocompiler = Nanoc3::Extra::AutoCompiler.new(site)

    # Fill response for 500
    response = autocompiler.instance_eval do
      begin
        raise RuntimeError.new("boink")
      rescue RuntimeError => e
        serve_500('/foo/bar/baz/', e)
      end
    end

    # Check response
    assert_equal(500,                     response[0])
    assert_equal('text/html',             response[1]['Content-Type'])
    assert_match(/500 Server Error/,      response[2][0])
    assert_match(/Unknown error: boink/,  response[2][0])
  end

  def test_serve_rep_with_working_page
    if_have('mime/types') do
      # Create page and page rep
      page = mock
      page_rep = mock
      page_rep.expects(:raw_path).at_least_once.returns('somefile.html')
      page_rep.expects(:item).returns(page)
      page_rep.expects(:content_at_snapshot).with(:post).returns('compiled page content')

      # Create file
      File.open(page_rep.raw_path, 'w') { |io| }

      # Create compiler
      compiler = Object.new
      def compiler.run(items, params={})
        File.open('somefile.html', 'w') { |io| io.write("... compiled page content ...") }
      end

      # Create site
      site = mock
      site.expects(:compiler).returns(compiler)

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new(site)

      begin
        # Serve
        response = autocompiler.instance_eval { serve_rep(page_rep) }

        # Check response
        assert_equal(200,                     response[0])
        assert_equal('text/html',             response[1]['Content-Type'])
        assert_match(/compiled page content/, response[2][0])
      ensure
        # Clean up
        FileUtils.rm_rf(page_rep.raw_path)
      end
    end
  end

  def test_serve_rep_with_broken_page
    if_have('mime/types') do
      # Create page and page rep
      page = mock
      page_rep = mock
      page_rep.expects(:path).returns('somefile.html')
      page_rep.expects(:item).returns(page)

      # Create site
      stack = []
      compiler = mock
      compiler.expects(:stack).returns(stack)
      compiler.expects(:run).raises(RuntimeError, 'aah! fail!')
      site = mock
      site.expects(:compiler).at_least_once.returns(compiler)

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new(site)

      # Serve
      response = autocompiler.instance_eval { serve_rep(page_rep) }

      # Check response
      assert_equal(500,                 response[0])
      assert_equal('text/html',         response[1]['Content-Type'])
      assert_match(/aah! fail!/,        response[2][0])
      assert_match(/500 Server Error/,  response[2][0])
    end
  end

  def test_serve_file
    if_have('mime/types') do
      # Create test files
      File.open('test.css', 'w') { |io| io.write("body { color: blue; }")  }
      File.open('test',     'w') { |io| io.write("random blah blah stuff") }

      # Create autocompiler
      autocompiler = Nanoc3::Extra::AutoCompiler.new(self)

      # Serve file 1
      response = autocompiler.instance_eval { serve_file('test.css') }

      # Check response for file 1
      assert_equal(200,         response[0])
      assert_equal('text/css',  response[1]['Content-Type'])
      assert(response[2][0].include?('body { color: blue; }'))

      # Serve file 2
      response = autocompiler.instance_eval { serve_file('test') }

      # Check response for file 2
      assert_equal(200,                         response[0])
      assert_equal('application/octet-stream',  response[1]['Content-Type'])
      assert(response[2][0].include?('random blah blah stuff'))
    end
  end

end
