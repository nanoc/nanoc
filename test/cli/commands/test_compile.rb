# encoding: utf-8

class Nanoc3::CLI::Commands::CompileTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_profiling_information
    with_site do |site|
      cli(%w(create_item foo))
      cli(%w(create_item bar))
      cli(%w(create_item baz))

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

      cli(%w(compile --verbose))
    end
  end

end
