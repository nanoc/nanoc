# encoding: utf-8

require 'test/helper'

class Nanoc3::CLI::Commands::CreateLayoutTest < Nanoc3::TestCase

  def test_can_compile_new_layout
    Nanoc3::CLI::Base.new.run([ 'create_site', 'foo' ])

    FileUtils.cd('foo') do
      # Create new layout
      Nanoc3::CLI::Base.new.run([ 'create_layout', 'moo' ])

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
