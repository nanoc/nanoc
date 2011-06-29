# encoding: utf-8

class Nanoc::CLI::Commands::CreateLayoutTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_can_compile_new_layout
    require 'nanoc/cli'

    Nanoc::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do
      # Create new layout
      Nanoc::CLI.run %w( create_layout moo )

      # Makes rules use new layout
      rules_raw = File.read('Rules')
      File.open('Rules', 'w') do |io|
        io.write rules_raw.sub("layout 'default'", "layout 'moo'")
      end

      site = Nanoc::Site.new('.')
      site.load_data
      site.compile
    end
  end

end
