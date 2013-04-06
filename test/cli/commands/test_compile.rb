# encoding: utf-8

class Nanoc::CLI::Commands::CompileTest < Nanoc::TestCase

  def test_profiling_information
    with_site do |site|
      Nanoc::CLI.run %w( create_item foo )
      Nanoc::CLI.run %w( create_item bar )
      Nanoc::CLI.run %w( create_item baz )

      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  filter :erb\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  if item.binary?\n"
        io.write "    item.identifier.chop + '.' + item[:extension]\n"
        io.write "  else\n"
        io.write "    item.identifier + 'index.html'\n"
        io.write "  end\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      Nanoc::CLI.run %w( compile --verbose )
    end
  end

  def test_auto_prune
    with_site do |site|
      Nanoc::CLI.run %w( create_item foo )
      Nanoc::CLI.run %w( create_item bar )
      Nanoc::CLI.run %w( create_item baz )

      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  filter :erb\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  if item.binary?\n"
        io.write "    item.identifier.chop + '.' + item[:extension]\n"
        io.write "  else\n"
        io.write "    item.identifier + 'index.html'\n"
        io.write "  end\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      File.open('output/stray.html', 'w') do |io|
        io.write 'I am a stray file and I am about to be deleted!'
      end

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w( compile )
      assert File.file?('output/stray.html')

      File.open('nanoc.yaml', 'w') do |io|
        io.write "prune:\n"
        io.write "  auto_prune: true\n"
      end

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w( compile )
      refute File.file?('output/stray.html')
    end
  end

  def test_auto_prune_with_exclude
    with_site do |site|
      Nanoc::CLI.run %w( create_item foo )
      Nanoc::CLI.run %w( create_item bar )
      Nanoc::CLI.run %w( create_item baz )

      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  filter :erb\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  if item.binary?\n"
        io.write "    item.identifier.chop + '.' + item[:extension]\n"
        io.write "  else\n"
        io.write "    item.identifier + 'index.html'\n"
        io.write "  end\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      Dir.mkdir('output/excluded_dir')

      File.open('output/stray.html', 'w') do |io|
        io.write 'I am a stray file and I am about to be deleted!'
      end

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w( compile )
      assert File.file?('output/stray.html')

      File.open('nanoc.yaml', 'w') do |io|
        io.write "prune:\n"
        io.write "  auto_prune: true\n"
        io.write "  exclude: [ 'excluded_dir' ]\n"
      end

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w( compile )
      refute File.file?('output/stray.html')
      assert File.directory?('output/excluded_dir'),
        'excluded_dir should still be there'
    end
  end

  def test_setup_and_teardown_listeners
    with_site do
      test_listener_class = Class.new(::Nanoc::CLI::Commands::Compile::Listener) do
        def start ; @started = true ; end
        def stop  ; @stopped = true ; end
        def started? ; @started ; end
        def stopped? ; @stopped ; end
      end

      options = {}
      arguments = []
      cmd = nil
      listener_classes = [ test_listener_class ]
      cmd_runner = Nanoc::CLI::Commands::Compile.new(
        options, arguments, cmd, :listener_classes => listener_classes)

      cmd_runner.run

      listeners = cmd_runner.send(:listeners)
      assert listeners.size == 1
      assert listeners.first.started?
      assert listeners.first.stopped?
    end
  end

end
