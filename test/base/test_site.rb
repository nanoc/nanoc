require 'test/helper'

class Nanoc3::SiteTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  class TestDataSource < Nanoc3::DataSource

    identifier :test_data_source

    def code ; Nanoc3::Code.new('') ; end

  end

  class TestNewschoolDataSource < Nanoc3::DataSource

    identifier :test_newschool_data_source

    def items
      [
        Nanoc3::Item.new("Hi!",          {}, '/'),
        Nanoc3::Item.new("Hello there.", {}, '/about/')
      ]
    end

    def layouts
      [
        Nanoc3::Layout.new(
          'HEADER <%= yield %> FOOTER',
          { :filter => 'erb' },
          '/quux/'
        )
      ]
    end

    def code
      Nanoc3::Code.new("def something_random ; 'something random, yah' ; end")
    end

  end

  class TestEarlyLoadingCodeDataSource < Nanoc3::DataSource

    identifier :early_loading_code_data_source

    def items
      [
        Nanoc3::Item.new("Hi!",          {}, '/'),
        Nanoc3::Item.new("Hello there.", {}, '/about/')
      ]
    end

    def layouts
      [
        Nanoc3::Layout.new(
          'HEADER <%= yield %> FOOTER',
          { :filter => 'erb' },
          '/quux/'
        )
      ]
    end

    def code
      Nanoc3::Code.new(
        "class TestEarlyLoadingCodeRouter < Nanoc3::Router\n" +
        "  identifier :early_loading_code_router\n" +
        "  def path_for(item)     ; 'web path'  ; end\n" +
        "  def raw_path_for(item) ; 'disk path' ; end\n" +
        "end"
      )
    end

  end

  def test_initialize_custom_router
    Nanoc3::Site.new(
      :output_dir   => 'output',
      :data_source  => 'early_loading_code_data_source',
      :router       => 'early_loading_code_router'
    )
  end

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
