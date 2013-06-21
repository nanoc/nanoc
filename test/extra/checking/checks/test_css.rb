# encoding: utf-8

class Nanoc::Extra::Checking::Checks::CSSTest < Nanoc::TestCase

  def test_run_ok
    if_have 'w3c_validators' do
      in_site do
        # Create files
        FileUtils.mkdir_p('output')
        File.write('output/blah.html', '<h1>Hi!</h1>')
        File.write('output/style.css', 'h1 { color: red; }')

        # Run check
        check = Nanoc::Extra::Checking::Checks::CSS.new(site_here)
        check.run

        # Check
        assert check.issues.empty?
      end
    end
  end

  def test_run_error
    if_have 'w3c_validators' do
      in_site do
        # Create files
        FileUtils.mkdir_p('output')
        File.write('output/blah.html', '<h1>Hi!</h1>')
        File.write('output/style.css', 'h1 { coxlor: rxed; }')

        # Run check
        check = Nanoc::Extra::Checking::Checks::CSS.new(site_here)
        check.run

        # Check
        refute check.issues.empty?
      end
    end
  end

end

