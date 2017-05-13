# frozen_string_literal: true

require 'helper'

class Nanoc::CLI::ErrorHandlerTest < Nanoc::TestCase
  def setup
    super
    @handler = Nanoc::CLI::ErrorHandler.new
  end

  def test_resolution_for_with_unknown_gem
    error = LoadError.new('no such file to load -- afjlrestjlsgrshter')
    assert_nil @handler.send(:resolution_for, error)
  end

  def test_resolution_for_with_known_gem_without_bundler
    def @handler.using_bundler?
      false
    end
    error = LoadError.new('no such file to load -- kramdown')
    assert_match(/^Install the 'kramdown' gem using `gem install kramdown`./, @handler.send(:resolution_for, error))
  end

  def test_resolution_for_with_known_gem_with_bundler
    def @handler.using_bundler?
      true
    end
    error = LoadError.new('no such file to load -- kramdown')
    assert_match(/^Make sure the gem is added to Gemfile/, @handler.send(:resolution_for, error))
  end

  def test_resolution_for_with_not_load_error
    error = RuntimeError.new('nuclear meltdown detected')
    assert_nil @handler.send(:resolution_for, error)
  end

  def test_write_stack_trace_verbose
    error = new_error(20)

    stream = StringIO.new
    @handler.send(:write_stack_trace, stream, error, verbose: false)
    assert_match(/See full crash log for details./, stream.string)

    stream = StringIO.new
    @handler.send(:write_stack_trace, stream, error, verbose: false)
    assert_match(/See full crash log for details./, stream.string)

    stream = StringIO.new
    @handler.send(:write_stack_trace, stream, error, verbose: true)
    refute_match(/See full crash log for details./, stream.string)
  end

  def test_write_error_message_wrapped
    stream = StringIO.new
    @handler.send(:write_error_message, stream, new_wrapped_error(new_error), verbose: true)
    refute_match(/CompilationError/, stream.string)
  end

  def test_write_stack_trace_wrapped
    stream = StringIO.new
    @handler.send(:write_stack_trace, stream, new_wrapped_error(new_error), verbose: false)
    assert_match(/new_error/, stream.string)
  end

  def test_write_item_rep
    stream = StringIO.new
    @handler.send(:write_item_rep, stream, new_wrapped_error(new_error), verbose: false)
    assert_match(/^Item identifier: \/about\.md$/, stream.string)
    assert_match(/^Item rep name:   :latex$/, stream.string)
  end

  def test_resolution_for_wrapped
    def @handler.using_bundler?
      true
    end
    error = new_wrapped_error(LoadError.new('no such file to load -- kramdown'))
    assert_match(/^Make sure the gem is added to Gemfile/, @handler.send(:resolution_for, error))
  end

  def new_wrapped_error(wrapped)
    item = Nanoc::Int::Item.new('asdf', {}, '/about.md')
    item_rep = Nanoc::Int::ItemRep.new(item, :latex)
    raise Nanoc::Int::Errors::CompilationError.new(wrapped, item_rep)
  rescue => e
    return e
  end

  def new_error(amount_factor = 1)
    backtrace_generator = lambda do |af|
      if af.zero?
        raise 'finally!'
      else
        backtrace_generator.call(af - 1)
      end
    end

    begin
      backtrace_generator.call(amount_factor)
    rescue => e
      return e
    end
  end
end
