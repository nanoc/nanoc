# encoding: utf-8

class Nanoc::Extra::Checking::DSLTest < Nanoc::TestCase

  def test_from_file
    with_site do |site|
      File.open('Checks', 'w') { |io| io.write("check :foo do\n\nend\ndeploy_check :bar\n") }
      dsl = Nanoc::Extra::Checking::DSL.from_file('Checks')

      # One new check
      refute Nanoc::Extra::Checking::Check.named(:foo).nil?

      # One check marked for deployment
      assert_equal [ :bar ], dsl.deploy_checks
    end
  end

end
