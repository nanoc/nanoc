# frozen_string_literal: true

require 'rouge'

describe Nanoc::Filters::ColorizeSyntax, filter: true do
  subject { filter.setup_and_run(input, default_colorizer: :rouge, rouge: params) }

  let(:filter) { described_class.new }
  let(:params) { {} }
  let(:wrap) { false }
  let(:css_class) { 'highlight' }
  let(:input) do
    <<~EOS
      before
      <pre><code class="language-ruby">
        def foo
        end
      </code></pre>
      after
    EOS
  end
  let(:output) do
    <<~EOS
      before
      <pre><code class="language-ruby#{wrap ? " #{css_class}" : ''}">  <span class="k">def</span> <span class="nf">foo</span>
        <span class="k">end</span></code></pre>
      after
    EOS
  end

  context 'with Rouge' do
    context 'with default options' do
      it { is_expected.to eql output }
    end

    context 'with legacy' do
      let(:legacy) { true }
      let(:params) { super().merge(legacy:) }

      it { is_expected.to eql output }

      context 'with pygments wrapper' do
        let(:wrap) { true }
        let(:params) { super().merge(wrap:) }

        it { is_expected.to eql output }

        context 'with css_class' do
          let(:css_class) { 'nanoc' }
          let(:params) { super().merge(css_class:) }

          it { is_expected.to eql output }
        end
      end

      context 'with line number' do
        let(:line_numbers) { true }
        let(:params) { super().merge(line_numbers:) }
        let(:output) do
          <<~EOS
            before
            <pre><code class="language-ruby"><table class="rouge-table"><tbody><tr>
            <td class="rouge-gutter gl"><pre class="lineno">1
            2
            </pre></td>
            <td class="rouge-code"><pre>  <span class="k">def</span> <span class="nf">foo</span>
              <span class="k">end</span>
            </pre></td>
            </tr></tbody></table></code></pre>
            after
          EOS
        end

        it { is_expected.to eql output }
      end
    end

    context 'with formater' do
      let(:params) { super().merge(formatter:) }

      context 'with inline' do
        let(:formatter) { Rouge::Formatters::HTMLInline.new(theme) }

        context 'with github theme' do
          let(:theme) { Rouge::Themes::Github.new }
          let(:output) do
            <<~EOS
              before
              <pre><code class="language-ruby">  <span style="color: #cf222e">def</span> <span style="color: #8250df">foo</span>
                <span style="color: #cf222e">end</span></code></pre>
              after
            EOS
          end

          it { is_expected.to eql output }
        end

        context 'with colorful theme' do
          let(:theme) { Rouge::Themes::Colorful.new }
          let(:output) do
            <<~EOS
              before
              <pre><code class="language-ruby">  <span style="color: #080;font-weight: bold">def</span> <span style="color: #06B;font-weight: bold">foo</span>
                <span style="color: #080;font-weight: bold">end</span></code></pre>
              after
            EOS
          end

          it { is_expected.to eql output }
        end
      end

      context 'with linewise' do
        let(:formatter) { Rouge::Formatters::HTMLLinewise.new(Rouge::Formatters::HTML.new) }
        let(:output) do
          <<~EOS
            before
            <pre><code class="language-ruby"><div class="line-1">  <span class="k">def</span> <span class="nf">foo</span>
            </div>
            <div class="line-2">  <span class="k">end</span>
            </div></code></pre>
            after
          EOS
        end

        it { is_expected.to eql output }
      end

      context 'with pygments' do
        let(:wrap) { true }
        let(:css_class) { 'codehilite' }
        let(:formatter) { Rouge::Formatters::HTMLPygments.new(Rouge::Formatters::HTML.new) }

        it { is_expected.to eql output }
      end

      context 'with table' do
        let(:formatter) { Rouge::Formatters::HTMLTable.new(Rouge::Formatters::HTML.new) }
        let(:output) do
          <<~EOS
            before
            <pre><code class="language-ruby"><table class="rouge-table"><tbody><tr>
            <td class="rouge-gutter gl"><pre class="lineno">1
            2
            </pre></td>
            <td class="rouge-code"><pre>  <span class="k">def</span> <span class="nf">foo</span>
              <span class="k">end</span>
            </pre></td>
            </tr></tbody></table></code></pre>
            after
          EOS
        end

        it { is_expected.to eql output }
      end
    end
  end
end
