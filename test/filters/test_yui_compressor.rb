# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::YUICompressorTest < Nanoc::TestCase
  def test_filter_javascript
    if_have 'yuicompressor' do
      filter = ::Nanoc::Filters::YUICompressor.new

      sample_js = <<-JAVASCRIPT
        function factorial(n) {
            var result = 1;
            for (var i = 2; i <= n; i++) {
                result *= i
            }
            return result;
        }
      JAVASCRIPT

      result = filter.setup_and_run(sample_js, type: 'js', munge: true)
      assert_match 'function factorial(c){var a=1;for(var b=2;b<=c;b++){a*=b}return a};', result

      result = filter.setup_and_run(sample_js, type: 'js', munge: false)
      assert_match 'function factorial(n){var result=1;for(var i=2;i<=n;i++){result*=i}return result};', result
    end
  end

  def test_filter_css
    if_have 'yuicompressor' do
      filter = ::Nanoc::Filters::YUICompressor.new

      sample_css = <<-CSS
        * {
          margin: 0;
        }
      CSS

      result = filter.setup_and_run(sample_css, type: 'css')
      assert_match '*{margin:0}', result
    end
  end
end
