# frozen_string_literal: true

module Nanoc::Filters::ColorizeSyntax::Colorizers
  class Abstract
    extend DDPlugin::Plugin

    def process(_code, _language, params = {}) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError
    end

    def postprocess(_language, _element); end

    private

    def check_availability(*cmd)
      piper = Nanoc::Extra::Piper.new(stdout: StringIO.new, stderr: StringIO.new)
      piper.run(cmd, nil)
    end
  end

  class DummyColorizer < Abstract
    identifier :dummy

    def process(code, language, params = {}) # rubocop:disable Lint/UnusedMethodArgument
      code
    end
  end

  class CoderayColorizer < Abstract
    identifier :coderay

    def process(code, language, params = {})
      require 'coderay'

      ::CodeRay.scan(code, language).html(params)
    end

    def postprocess(_language, element)
      # Skip if we're a free <code>
      return if element.parent.nil?

      # <div class="code">
      div_inner = Nokogiri::XML::Node.new('div', element.document)
      div_inner['class'] = 'code'
      div_inner.children = element.dup

      # <div class="CodeRay">
      div_outer = Nokogiri::XML::Node.new('div', element.document)
      div_outer['class'] = 'CodeRay'
      div_outer.children = div_inner

      # orig element
      element.swap div_outer
    end
  end

  class PygmentizeColorizer < Abstract
    identifier :pygmentize

    def process(code, language, params = {})
      check_availability('pygmentize', '-V')

      params[:encoding] ||= 'utf-8'
      params[:nowrap] ||= 'True'

      cmd = ['pygmentize', '-l', language, '-f', 'html']
      cmd << '-O' << params.map { |k, v| "#{k}=#{v}" }.join(',') unless params.empty?

      stdout = StringIO.new
      stderr = $stderr
      piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)
      piper.run(cmd, code)

      stdout.string
    end
  end

  class PygmentsrbColorizer < Abstract
    identifier :pygmentsrb

    def process(code, language, params = {})
      require 'pygments'

      args = params.dup
      args[:lexer] ||= language
      args[:options] ||= {}
      args[:options][:encoding] ||= 'utf-8'
      args[:options][:nowrap] ||= 'True'

      Pygments.highlight(code, args)
    end
  end

  class SimonHighlightColorizer < Abstract
    identifier :simon_highlight

    SIMON_HIGHLIGHT_OPT_MAP = {
      wrap: '-W',
      include_style: '-I',
      line_numbers: '-l',
    }.freeze

    def process(code, language, params = {})
      check_availability('highlight', '--version')

      cmd = ['highlight', '--syntax', language, '--fragment']
      params.each do |key, _value|
        if SIMON_HIGHLIGHT_OPT_MAP[key]
          cmd << SIMON_HIGHLIGHT_OPT_MAP[key]
        else
          # TODO: allow passing other options
          case key
          when :style
            cmd << '--style' << params[:style]
          end
        end
      end

      stdout = StringIO.new
      stderr = $stderr
      piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)
      piper.run(cmd, code)

      stdout.string
    end
  end

  class RougeColorizer < Abstract
    identifier :rouge

    def process(code, language, params = {})
      require 'rouge'

      if Rouge.version < '2' || params.fetch(:legacy, false)
        # Rouge 1.x or Rouge 2.x legacy options
        formatter_options = {
          css_class: params.fetch(:css_class, 'highlight'),
          inline_theme: params.fetch(:inline_theme, nil),
          line_numbers: params.fetch(:line_numbers, false),
          start_line: params.fetch(:start_line, 1),
          wrap: params.fetch(:wrap, false),
        }
        formatter_cls = Rouge::Formatters.const_get(Rouge.version < '2' ? 'HTML' : 'HTMLLegacy')
        formatter = formatter_cls.new(formatter_options)
      else
        formatter = params.fetch(:formatter, Rouge::Formatters::HTML.new)
      end

      lexer = Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText
      formatter.format(lexer.lex(code))
    end

    def postprocess(_language, element)
      # Removes the double wrapping.
      #
      # Before:
      #
      #   <pre><code class="language-ruby"><pre class="highlight"><code>
      #
      # After:
      #
      #   <pre><code class="language-ruby highlight">

      return if element.name != 'pre'

      code1 = element.xpath('code').first
      return if code1.nil?

      div = code1.xpath('div').first
      return if div.nil?

      # For Rouge 2.x and 1.x, respectively
      pre = div.xpath('pre').first || code1.xpath('pre').first
      return if pre.nil?

      code2 = pre.xpath('code').first
      return if code2.nil?

      code1.inner_html = code2.inner_html
      code1['class'] = [code1['class'], pre['class']].compact.join(' ')
    end
  end
end
