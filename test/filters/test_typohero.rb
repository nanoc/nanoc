# encoding: utf-8

class Nanoc::Filters::TypoHeroTest < Nanoc::TestCase

  def test_filter
    if_have 'typohero' do
      # Get filter
      filter = ::Nanoc::Filters::TypoHero.new

      # Run filter
      a = '"TypoHero makes HTML look smarter &amp; better, don\'t you think?"'
      b = "<span class=\"dquo\">“</span>TypoHero makes <span class=\"caps\">HTML</span> look smarter <span class=\"amp\">&amp;</span> better, don’t you think?”"
      result = filter.setup_and_run(a)
      assert_equal(b, result)
    end
  end

end

