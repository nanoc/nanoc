require 'simplecov'
SimpleCov.start

require 'nanoc'
require 'nanoc/cli'

# FIXME: This should not be necessary (breaks SimpleCov)
module Nanoc::CLI
  def self.setup_cleaning_streams
  end
end

Nanoc::CLI.setup

class HelperContext
  def initialize(mod)
    @config = Nanoc::Int::Configuration.new
    @reps = Nanoc::Int::ItemRepRepo.new
    @items = Nanoc::Int::IdentifiableCollection.new(@config)
    @mod = mod
  end

  def create_item(content, attributes, identifier, main: false)
    item = Nanoc::Int::Item.new(content, attributes, identifier)
    @items << item
    @item = item if main
    Nanoc::ItemWithRepsView.new(item, view_context)
  end

  def create_rep(item, path)
    rep = Nanoc::Int::ItemRep.new(item.unwrap, :default)
    rep.paths[:last] = path
    @reps << rep
    Nanoc::ItemRepView.new(rep, view_context)
  end

  def helper
    mod = @mod
    klass = Class.new(Nanoc::Int::Context) { include mod }
    klass.new(assigns)
  end

  def config
    assigns[:config]
  end

  private

  def view_context
    Nanoc::ViewContext.new(reps: @reps, items: @items)
  end

  def assigns
    {
      config: Nanoc::MutableConfigView.new(@config, view_context),
      item: @item ? Nanoc::ItemWithRepsView.new(@item, view_context) : nil,
      items: Nanoc::ItemCollectionWithRepsView.new(@items, view_context)
    }
  end
end

RSpec.configure do |c|
  c.around(:each) do |example|
    Nanoc::CLI::ErrorHandler.disable
    example.run
    Nanoc::CLI::ErrorHandler.enable
  end

  c.around(:each) do |example|
    Dir.mktmpdir('nanoc-test') do |dir|
      FileUtils.cd(dir) do
        example.run
      end
    end
  end

  c.before(:each, site: true) do
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('layouts')
    FileUtils.mkdir_p('lib')
    FileUtils.mkdir_p('output')

    File.write('nanoc.yaml', '{}')

    File.write('Rules', 'passthrough "/**/*"')
  end
end

RSpec::Matchers.define :raise_frozen_error do |_expected|
  match do |actual|
    begin
      actual.call
      false
    rescue => e
      if e.is_a?(RuntimeError) || e.is_a?(TypeError)
        e.message =~ /(^can't modify frozen |^unable to modify frozen object$)/
      else
        false
      end
    end
  end

  supports_block_expectations

  failure_message do |_actual|
    'expected that proc would raise a frozen error'
  end

  failure_message_when_negated do |_actual|
    'expected that proc would not raise a frozen error'
  end
end
