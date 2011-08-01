# encoding: utf-8

class Nanoc::Filters::YUITest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'yuicompressor' do

    filter = ::Nanoc::Filters::YUICompress.new
    sample_js = <<-JAVASCRIPT
      function factorial(n) {
          var result = 1;
          for (var i = 2; i <= n; i++) {
              result *= i
          }
          return result;
      }
    JAVASCRIPT

    sample_css = <<-CSS
      * {
        margin: 0;
      }

      body {
        font-family: arial, helvetica, verdana, sans-serif;
        max-width: 1024px;
        margin: 0 auto 0 auto;
        font-size: 10pt;
        color: #333333;
        padding: 5px;
      }

      .banner, .main {
        border-radius: 5px;
      }
    CSS

     result = filter.run(sample_js)
     assert_match "function factorial(c){var a=1;for(var b=2;b<=c;b++){a*=b}return a};", result

     result = filter.run(sample_js, {:munge => false})
     assert_match "function factorial(n){var result=1;for(var i=2;i<=n;i++){result*=i}return result};", result

     result = filter.run(sample_css, {:type => 'css'})
     assert_match "*{margin:0}body{font-family:arial,helvetica,verdana,sans-serif;max-width:1024px;margin:0 auto 0 auto;font-size:10pt;color:#333;padding:5px}.banner,.main{border-radius:5px}", result
    end
  end
end
