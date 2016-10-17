class Nanoc::Filters::ColorizeSyntax::PigmentizeTest < Nanoc::TestCase
  ROUGE_INPUT = <<EOS.freeze
before
<pre><code class="language-ruby">
  def foo
  end
</code></pre>
after
EOS

  def test_rouge_with_default_options
    if_have 'rouge', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get expected output
      expected_output = <<EOS
before
<pre><code class=\"language-ruby\">  <span class=\"k\">def</span> <span class=\"nf\">foo</span>
  <span class=\"k\">end</span></code></pre>
after
EOS

      # Run filter
      actual_output = filter.setup_and_run(ROUGE_INPUT, default_colorizer: :rouge)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_rouge_legacy_with_default_options
    if_have 'rouge', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get expected output
      expected_output = <<EOS
before
<pre><code class=\"language-ruby\">  <span class=\"k\">def</span> <span class=\"nf\">foo</span>
  <span class=\"k\">end</span></code></pre>
after
EOS

      # Run filter
      actual_output = filter.setup_and_run(
        ROUGE_INPUT,
        default_colorizer: :rouge,
        rouge: { legacy: true },
      )
      assert_equal(expected_output, actual_output)
    end
  end

  def test_rouge_legacy_with_pygments_wrapper
    if_have 'rouge', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get expected output
      expected_output = <<EOS
before
<pre><code class=\"language-ruby nanoc\">  <span class=\"k\">def</span> <span class=\"nf\">foo</span>
  <span class=\"k\">end</span></code></pre>
after
EOS

      # Run filter
      actual_output = filter.setup_and_run(
        ROUGE_INPUT,
        default_colorizer: :rouge,
        rouge: { legacy: true, css_class: 'nanoc', wrap: true },
      )

      assert_equal(expected_output, actual_output)
    end
  end

  def test_rouge_legacy_with_line_number
    if_have 'rouge', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get expected output
      expected_rouge_1_output = <<EOS
before
<pre><code class="language-ruby"><table style="border-spacing: 0"><tbody><tr>
<td class="gutter gl" style="text-align: right"><pre class="lineno">1
2</pre></td>
<td class="code"><pre>  <span class="k">def</span> <span class="nf">foo</span>
  <span class="k">end</span><span class="w">
</span></pre></td>
</tr></tbody></table></code></pre>
after
EOS

      expected_rouge_2_output = <<EOS
before
<pre><code class="language-ruby"><table class="rouge-table"><tbody><tr>
<td class="rouge-gutter gl"><pre class="lineno">1
2
</pre></td>
<td class="rouge-code"><pre>  <span class="k">def</span> <span class="nf">foo</span>
  <span class="k">end</span></pre></td>
</tr></tbody></table></code></pre>
after
EOS

      # Run filter
      actual_output = filter.setup_and_run(
        ROUGE_INPUT,
        default_colorizer: :rouge,
        rouge: { legacy: true, line_numbers: true },
      )

      assert_equal(Rouge.version < '2' ? expected_rouge_1_output : expected_rouge_2_output, actual_output)
    end
  end
end
