# encoding: utf-8

require 'test/helper'

class Nanoc3::SiteTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_load_rules_with_existing_rules_file
    # Mock DSL
    dsl = mock
    dsl.expects(:compile).with('*')

    # Create site
    site = Nanoc3::Site.new({})
    site.expects(:dsl).returns(dsl)

    # Create rules file
    File.open('Rules', 'w') do |io|
      io.write <<-EOF
compile '*' do |rep|
  rep.write
end
EOF
    end

    # Load rules
    site.send :load_rules
  end

  def test_load_rules_with_broken_rules_file
    # Mock DSL
    dsl = mock
    dsl.expects(:some_function_that_doesn_really_exist)
    dsl.expects(:weird_param_number_one)
    dsl.expects(:mysterious_param_number_two)

    # Create site
    site = Nanoc3::Site.new({})
    site.expects(:dsl).returns(dsl)

    # Create rules file
    File.open('Rules', 'w') do |io|
      io.write <<-EOF
some_function_that_doesn_really_exist(
weird_param_number_one,
mysterious_param_number_two
)
EOF
    end

    # Load rules
    site.send :load_rules
  end

end
