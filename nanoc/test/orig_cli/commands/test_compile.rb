# frozen_string_literal: true

require 'helper'

class Nanoc::CLI::Commands::CompileTest < Nanoc::TestCase
  def test_profiling_information
    with_site do |_site|
      File.open('content/foo.md', 'w') { |io| io << 'asdf' }
      File.open('content/bar.md', 'w') { |io| io << 'asdf' }
      File.open('content/baz.md', 'w') { |io| io << 'asdf' }

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

      Nanoc::CLI.run %w[compile --verbose]
    end
  end

  def test_auto_prune
    with_site do |_site|
      File.open('content/foo.md', 'w') { |io| io << 'asdf' }
      File.open('content/bar.md', 'w') { |io| io << 'asdf' }
      File.open('content/baz.md', 'w') { |io| io << 'asdf' }

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

      File.open('nanoc.yaml', 'w') do |io|
        io.write "string_pattern_type: legacy\n"
        io.write "prune:\n"
        io.write "  auto_prune: false\n"
      end

      File.write('output/stray.html', 'I am a stray file and I am about to be deleted!')

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w[compile]

      assert File.file?('output/stray.html')

      File.open('nanoc.yaml', 'w') do |io|
        io.write "string_pattern_type: legacy\n"
        io.write "prune:\n"
        io.write "  auto_prune: true\n"
      end

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w[compile]

      refute File.file?('output/stray.html')
    end
  end

  def test_auto_prune_with_exclude
    with_site do |_site|
      File.open('content/foo.md', 'w') { |io| io << 'asdf' }
      File.open('content/bar.md', 'w') { |io| io << 'asdf' }
      File.open('content/baz.md', 'w') { |io| io << 'asdf' }

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

      File.open('nanoc.yaml', 'w') do |io|
        io.write "string_pattern_type: legacy\n"
        io.write "prune:\n"
        io.write "  auto_prune: false\n"
      end

      File.write('output/stray.html', 'I am a stray file and I am about to be deleted!')

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w[compile]

      assert File.file?('output/stray.html')

      File.open('nanoc.yaml', 'w') do |io|
        io.write "string_pattern_type: legacy\n"
        io.write "prune:\n"
        io.write "  auto_prune: true\n"
        io.write "  exclude: [ 'excluded_dir' ]\n"
      end

      assert File.file?('output/stray.html')
      Nanoc::CLI.run %w[compile]

      refute File.file?('output/stray.html')
      assert File.directory?('output/excluded_dir'), 'excluded_dir should still be there'
    end
  end

  def test_file_action_printer_normal
    # Create data
    item = Nanoc::Core::Item.new('content', {}, '/a')
    rep = Nanoc::Core::ItemRep.new(item, :default)
    rep.raw_paths[:last] = ['output/foo.txt']
    rep.compiled = true

    # Listen
    listener = new_file_action_printer([rep])
    listener.start_safely
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, rep.raw_path, false, true).sync
    listener.stop_safely

    # Check
    assert_equal 1, listener.events.size
    assert_equal :high,            listener.events[0][:level]
    assert_equal :update,          listener.events[0][:action]
    assert_equal 'output/foo.txt', listener.events[0][:path]
    assert_in_delta 0.0,           listener.events[0][:duration], 1.0
  end

  def test_file_action_printer_skip
    # Create data
    item = Nanoc::Core::Item.new('content', {}, '/a')
    rep = Nanoc::Core::ItemRep.new(item, :default)
    rep.raw_paths[:last] = ['output/foo.txt']

    # Listen
    listener = new_file_action_printer([rep])
    listener.start_safely
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    listener.stop_safely

    # Check
    assert_equal 1, listener.events.size
    assert_equal :low,             listener.events[0][:level]
    assert_equal :skip,            listener.events[0][:action]
    assert_equal 'output/foo.txt', listener.events[0][:path]
    assert_nil listener.events[0][:duration]
  end

  def new_file_action_printer(reps)
    # Ensure CLI is loaded
    begin
      Nanoc::CLI.run(%w[help %])
    rescue SystemExit
    end

    listener = Nanoc::CLI::CompileListeners::FileActionPrinter.new(reps:)

    def listener.log(level, action, path, duration)
      @events ||= []
      @events << {
        level:,
        action:,
        path:,
        duration:,
      }
    end

    def listener.events
      @events
    end

    listener
  end
end
