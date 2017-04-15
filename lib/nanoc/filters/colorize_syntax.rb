module Nanoc::Filters
  # @api private
  class ColorizeSyntax < Nanoc::Filter
    identifier :colorize_syntax

    requires 'nokogiri', 'stringio', 'open3'

    DEFAULT_COLORIZER = :coderay

    def run(content, params = {})
      Nanoc::Extra::JRubyNokogiriWarner.check_and_warn

      # Take colorizers from parameters
      @colorizers = Hash.new(params[:default_colorizer] || DEFAULT_COLORIZER)
      (params[:colorizers] || {}).each_pair do |language, colorizer|
        @colorizers[language] = colorizer
      end

      syntax = params.fetch(:syntax, :html)
      parser = parser_for(syntax)

      # Colorize
      doc = parse(content, parser, params.fetch(:is_fullpage, false))
      selector = params[:outside_pre] ? 'code' : 'pre > code'
      doc.css(selector).each do |element|
        # Get language
        has_class = false
        language = nil
        if element['class']
          # Get language from class
          match = element['class'].match(/(^| )language-([^ ]+)/)
          language = match[2] if match
          has_class = true if language
        else
          # Get language from comment line
          match = element.inner_text.strip.split[0].match(/^#!([^\/][^\n]*)$/)
          language = match[1] if match
          element.content = element.content.sub(/^#!([^\/][^\n]*)$\n/, '') if language
        end

        # Give up if there is no hope left
        next if language.nil?

        # Highlight
        raw = strip(element.inner_text)
        highlighted_code = highlight(raw, language, params)
        element.children = parse_fragment(parser, strip(highlighted_code))

        # Add language-something class
        unless has_class
          klass = element['class'] || ''
          klass << ' ' unless [' ', nil].include?(klass[-1, 1])
          klass << "language-#{language}"
          element['class'] = klass
        end

        highlight_postprocess(language, element.parent)
      end

      serialize(doc, syntax)
    end

    def parser_for(syntax)
      case syntax
      when :html
        require 'nokogiri'
        Nokogiri::HTML
      when :html5
        require 'nokogumbo'
        Nokogiri::HTML5
      when :xml, :xhtml
        require 'nokogiri'
        Nokogiri::XML
      else
        raise "unknown syntax: #{syntax.inspect} (expected :html, :html5, or :xml)"
      end
    end

    def serialize(doc, syntax)
      case syntax
      when :html5
        doc.to_html
      else
        doc.send("to_#{syntax}", encoding: 'UTF-8')
      end
    end

    def parse_full(parser_class, content)
      if parser_class.to_s == 'Nokogiri::HTML5'
        parser_class.parse(content)
      else
        parser_class.parse(content, nil, 'UTF-8')
      end
    end

    def parse_fragment(parser_class, content)
      parser_class.fragment(content)
    end

    def parse(content, klass, is_fullpage)
      if is_fullpage
        parse_full(klass, content)
      else
        parse_fragment(klass, content)
      end
    rescue => e
      if e.message =~ /can't modify frozen string/
        parse(content.dup, klass, is_fullpage)
      else
        raise e
      end
    end

    class Colorizer
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

    class DummyColorizer < Colorizer
      identifier :dummy

      def process(code, language, params = {}) # rubocop:disable Lint/UnusedMethodArgument
        code
      end
    end

    class CoderayColorizer < Colorizer
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

    class PygmentizeColorizer < Colorizer
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

    class PygmentsrbColorizer < Colorizer
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

    class SimonHighlightColorizer < Colorizer
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

    class RougeColorizer < Colorizer
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

        pre = code1.xpath('pre').first
        return if pre.nil?

        code2 = pre.xpath('code').first
        return if code2.nil?

        code1.inner_html = code2.inner_html
        code1['class'] = [code1['class'], pre['class']].compact.join(' ')
      end
    end

    protected

    # Removes the first blank lines and any whitespace at the end.
    def strip(s)
      s.lines.drop_while { |line| line.strip.empty? }.join.rstrip
    end

    def highlight(code, language, params = {})
      colorizer_name = @colorizers[language.to_sym]
      colorizer = Colorizer.named(colorizer_name.to_sym)
      if colorizer
        colorizer.new.process(code, language, params[colorizer_name] || {})
      else
        raise "I don’t know how to highlight code using the “#{colorizer_name}” colorizer"
      end
    end

    def highlight_postprocess(language, element)
      colorizer_name = @colorizers[language.to_sym]
      colorizer = Colorizer.named(colorizer_name.to_sym)
      if colorizer
        colorizer.new.postprocess(language, element)
      else
        raise "I don’t know how to highlight code using the “#{colorizer}” colorizer"
      end
    end
  end
end
