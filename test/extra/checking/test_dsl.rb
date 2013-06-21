# encoding: utf-8

class Nanoc::Extra::Checking::DSLTest < Nanoc::TestCase

  def test_from_file
    in_site do
      File.write('Checks', "check :foo do\n\nend\ndeploy_check :bar\n")
      dsl = Nanoc::Extra::Checking::DSL.from_file('Checks')

      # One new check
      refute Nanoc::Extra::Checking::Check.named(:foo).nil?

      # One check marked for deployment
      assert_equal [ :bar ], dsl.deploy_checks
    end
  end

end
