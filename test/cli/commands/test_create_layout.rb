# encoding: utf-8

class Nanoc3::CLI::Commands::CreateLayoutTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_can_compile_new_layout
    require 'nanoc3/cli'

    Nanoc3::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do
      # Create new layout
      Nanoc3::CLI.run %w( create_layout moo )

      # Makes rules use new layout
      rules_raw = File.read('Rules')
      File.open('Rules', 'w') do |io|
        io.write rules_raw.sub("layout 'default'", "layout 'moo'")
      end

      site = Nanoc3::Site.new('.')
      site.load_data
      site.compile
    end
  end

end
