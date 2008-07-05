require 'helper'

class Nanoc::AutoCompilerTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_start
    # TODO implement
  end

  def test_preferred_handler
    # Create autocompiler
    aco = Nanoc::AutoCompiler.new(nil)

    # Check preferred handler
    handlers = sequence('handlers')
    aco.expects(:handler_named).with(:thin).returns(nil).in_sequence(handlers)
    aco.expects(:handler_named).with(:mongrel).returns(':D').in_sequence(handlers)
    assert_equal(':D', aco.instance_eval { preferred_handler })
  end

  def test_handler_named
    if_have('rack') do
      # Create autocompiler
      autocompiler = Nanoc::AutoCompiler.new(nil)

      # Check handler without requirements
      assert_equal(
        Rack::Handler::WEBrick,
        autocompiler.instance_eval { handler_named(:webrick) }
      )

      # Check handler with requirements
      assert_raises(NameError) do
        Rack::Handler::Thin
      end
      assert_nothing_raised do
        autocompiler.instance_eval { handler_named(:thin) }
        assert_equal(
          Rack::Handler::Thin,
          autocompiler.instance_eval { handler_named(:thin) }
        )
      end
    end
  end

  def test_handle_request_with_page_rep
    # Create pages and reps
    page_reps = [ mock, mock, mock ]
    page_reps[0].expects(:web_path).at_most_once.returns('/foo/1/')
    page_reps[1].expects(:web_path).returns('/foo/2/')
    page_reps[2].expects(:web_path).at_most_once.returns('/bar/')
    pages = [ mock, mock ]
    pages[0].expects(:reps).returns([ page_reps[0], page_reps[1] ])
    pages[1].expects(:reps).returns([ page_reps[2] ])

    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns(pages)
    site.expects(:config).returns({ :output_dir => 'output/' })

    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(site)
    autocompiler.expects(:serve_page_rep).with(page_reps[1])

    # Run
    autocompiler.instance_eval { handle_request('/foo/2/') }
  end

  def test_handle_request_with_file
    # Create pages and reps
    page_reps = [ mock, mock, mock ]
    page_reps[0].expects(:web_path).returns('/foo/1/')
    page_reps[1].expects(:web_path).returns('/foo/2/')
    page_reps[2].expects(:web_path).returns('/bar/')
    pages = [ mock, mock ]
    pages[0].expects(:reps).returns([ page_reps[0], page_reps[1] ])
    pages[1].expects(:reps).returns([ page_reps[2] ])

    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns(pages)
    site.expects(:config).returns({ :output_dir => 'tmp/' })

    # Create file
    File.open('tmp/somefile.txt', 'w') { |io| }

    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(site)
    autocompiler.expects(:serve_file).with('tmp/somefile.txt')

    # Run
    autocompiler.instance_eval { handle_request('somefile.txt') }
  end

  def test_handle_request_with_404
    # Create pages and reps
    page_reps = [ mock, mock, mock ]
    page_reps[0].expects(:web_path).returns('/foo/1/')
    page_reps[1].expects(:web_path).returns('/foo/2/')
    page_reps[2].expects(:web_path).returns('/bar/')
    pages = [ mock, mock ]
    pages[0].expects(:reps).returns([ page_reps[0], page_reps[1] ])
    pages[1].expects(:reps).returns([ page_reps[2] ])

    # Create site
    site = mock
    site.expects(:load_data).with(true)
    site.expects(:pages).returns(pages)
    site.expects(:config).returns({ :output_dir => 'tmp/' })

    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(site)
    autocompiler.expects(:serve_404).with('someotherfile.txt')

    # Run
    autocompiler.instance_eval { handle_request('someotherfile.txt') }
  end

  def test_h
    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(nil)

    # Check HTML escaping
    assert_equal(
      '&lt; &amp; &gt; \' &quot;',
      autocompiler.instance_eval { h('< & > \' "') }
    )
  end

  def test_mime_type_of
    if_have('mime/types') do
      # Create autocompiler
      autocompiler = Nanoc::AutoCompiler.new(nil)

      # Create known test file
      File.open('tmp/foo.html', 'w') { |io| }
      assert_equal(
        'text/html',
        autocompiler.instance_eval { mime_type_of('tmp/foo.html', 'huh') }
      )

      # Create unknown test file
      File.open('tmp/foo', 'w') { |io| }
      assert_equal(
        'huh',
        autocompiler.instance_eval { mime_type_of('tmp/foo', 'huh') }
      )
    end
  end

  def test_serve_400
    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(nil)

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
    autocompiler = Nanoc::AutoCompiler.new(site)

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

  def test_serve_page_rep_with_working_page
    if_have('mime/types') do
      # Create page and page rep
      page = mock
      page_rep = mock
      page_rep.expects(:disk_path).at_least_once.returns('tmp/somefile.html')
      page_rep.expects(:page).returns(page)
      page_rep.expects(:content).with(:post).returns('compiled page content')

      # Create file
      File.open(page_rep.disk_path, 'w') { |io| }

      # Create site
      compiler = mock
      compiler.expects(:run)
      site = mock
      site.expects(:compiler).returns(compiler)

      # Create autocompiler
      autocompiler = Nanoc::AutoCompiler.new(site)

      begin
        assert_nothing_raised do
          # Serve
          response = autocompiler.instance_eval { serve_page_rep(page_rep) }

          # Check response
          assert_equal(200,                     response[0])
          assert_equal('text/html',             response[1]['Content-Type'])
          assert_match(/compiled page content/, response[2][0])
        end
      ensure
        # Clean up
        FileUtils.remove_entry_secure(page_rep.disk_path)
      end
    end
  end

  def test_serve_page_rep_with_broken_page
    if_have('mime/types') do
      # Create page and page rep
      page = mock
      page_rep = mock
      page_rep.expects(:web_path).returns('somefile.html')
      page_rep.expects(:page).returns(page)

      # Create site
      stack = []
      compiler = mock
      compiler.expects(:stack).returns(stack)
      compiler.expects(:run).raises(RuntimeError, 'aah! fail!')
      site = mock
      site.expects(:compiler).at_least_once.returns(compiler)

      # Create autocompiler
      autocompiler = Nanoc::AutoCompiler.new(site)

      assert_nothing_raised do
        # Serve
        response = autocompiler.instance_eval { serve_page_rep(page_rep) }

        # Check response
        assert_equal(500,                 response[0])
        assert_equal('text/html',         response[1]['Content-Type'])
        assert_match(/aah! fail!/,        response[2][0])
        assert_match(/500 Server Error/,  response[2][0])
      end
    end
  end

  def test_serve_file
    if_have('mime/types') do
      # Create test files
      File.open('tmp/test.css', 'w') { |io| io.write("body { color: blue; }")  }
      File.open('tmp/test',     'w') { |io| io.write("random blah blah stuff") }

      # Create autocompiler
      autocompiler = Nanoc::AutoCompiler.new(self)

      # Test file 1
      assert_nothing_raised do
        # Serve
        response = autocompiler.instance_eval { serve_file('tmp/test.css') }

        # Check response
        assert_equal(200,         response[0])
        assert_equal('text/css',  response[1]['Content-Type'])
        assert(response[2][0].include?('body { color: blue; }'))
      end

      # Test file 2
      assert_nothing_raised do
        # Serve
        response = autocompiler.instance_eval { serve_file('tmp/test') }

        # Check response
        assert_equal(200,                         response[0])
        assert_equal('application/octet-stream',  response[1]['Content-Type'])
        assert(response[2][0].include?('random blah blah stuff'))
      end
    end
  end

end
