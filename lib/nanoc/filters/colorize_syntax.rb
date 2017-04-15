module Nanoc::Filters
  # @api private
  class ColorizeSyntax < Nanoc::Filter
    identifier :colorize_syntax

    requires 'nokogiri', 'stringio', 'open3'

    # The default colorizer to use for a language if the colorizer for that
    # language is not overridden.
    DEFAULT_COLORIZER = :coderay

    # Syntax-highlights code blocks in the given content. Code blocks should
    # be enclosed in `pre` elements that contain a `code` element. The code
    # element should have an indication of the language the code is in. There
    # are two possible ways of adding such an indication:
    #
    # 1. A HTML class starting with `language-` and followed by the
    # code language, as specified by HTML5. For example, `<code class="language-ruby">`.
    #
    # 2. A comment on the very first line of the code block in the format
    # `#!language` where `language` is the language the code is in. For
    # example, `#!ruby`.
    #
    # Options for individual colorizers will be taken from the {#run}
    # options’ value for the given colorizer. For example, if the filter is
    # invoked with a `:coderay => coderay_options_hash` option, the
    # `coderay_options_hash` hash will be passed to the CodeRay colorizer.
    #
    # Currently, the following colorizers are supported:
    #
    # * `:coderay` for [Coderay](http://coderay.rubychan.de/)
    # * `:pygmentize` for [pygmentize](http://pygments.org/docs/cmdline/), the
    #   command-line frontend for [Pygments](http://pygments.org/)
    # * `:pygmentsrb` for [pygments.rb](https://github.com/tmm1/pygments.rb),
    #   a Ruby interface for [Pygments](http://pygments.org/)
    # * `:simon_highlight` for [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.html)
    # * `:rouge` for [Rouge](https://github.com/jayferd/rouge/)
    #
    # Additional colorizer implementations are welcome!
    #
    # @example Using a class to indicate type of code be highlighted
    #
    #     <pre><code class="language-ruby">
    #     def foo
    #       "asdf"
    #     end
    #     </code></pre>
    #
    # @example Using a comment to indicate type of code be highlighted
    #
    #     <pre><code>
    #     #!ruby
    #     def foo
    #       "asdf"
    #     end
    #     </code></pre>
    #
    # @example Invoking the filter with custom parameters
    #
    #     filter :colorize_syntax,
    #            :colorizers => { :ruby => :coderay },
    #            :coderay    => { :line_numbers => :list }
    #
    # @param [String] content The content to filter
    #
    # @option params [Symbol] :default_colorizer (DEFAULT_COLORIZER) The
    #   default colorizer, i.e. the colorizer that will be used when the
    #   colorizer is not overriden for a specific language.
    #
    # @option params [Symbol] :syntax (:html) The syntax to use, which can be
    #   `:html`, `:xml` or `:xhtml`, the latter two being the same.
    #
    # @option params [Hash] :colorizers ({}) A hash containing
    #   a mapping of programming languages (symbols, not strings) onto
    #   colorizers (symbols).
    #
    # @option params [Boolean] :outside_pre (false) `true` if the colorizer
    #   should be applied on `code` elements outside `pre` elements, false
    #   if only `code` elements inside` pre` elements should be colorized.
    #
    # @option params [Symbol] :is_fullpage (false) Whether to treat the input
    #   as a full HTML page or a page fragment. When true, HTML boilerplate
    #   such as the doctype, `html`, `head` and `body` elements will be added.
    #
    # @return [String] The filtered content
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

      case syntax
      when :html5
        doc.to_s
      else
        doc.send("to_#{syntax}", encoding: 'UTF-8')
      end
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

    # Parses the given content using the given class. This method also handles
    # an issue with Nokogiri on JRuby causing “cannot modify frozen string”
    # errors.
    #
    # @param [String] content The content to parse
    #
    # @param [Class] klass The Nokogiri parser class
    #
    # @param [Boolean] is_fullpage true if the given content is a full page,
    #   false if it is a fragment
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

    # Runs the code through [CodeRay](http://coderay.rubychan.de/).
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @param [Hash] params Parameters to pass on to CodeRay
    #
    # @return [String] The colorized output
    def coderay(code, language, params = {})
      require 'coderay'

      ::CodeRay.scan(code, language).html(params)
    end

    # Returns the input itself, not performing any code highlighting.
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in (unused)
    #
    # @return [String] The colorized output, which is identical to the input
    #   in this case
    def dummy(code, language, params = {}) # rubocop:disable Lint/UnusedMethodArgument
      code
    end

    # Runs the content through [pygmentize](http://pygments.org/docs/cmdline/),
    # the command-line frontend for [Pygments](http://pygments.org/).
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @option params [String, Symbol] :encoding The encoding of the code block
    #
    # @return [String] The colorized output
    def pygmentize(code, language, params = {})
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

    # Runs the content through [Pygments](http://pygments.org/) via
    # [pygments.rb](https://github.com/tmm1/pygments.rb).
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @return [String] The colorized output
    def pygmentsrb(code, language, params = {})
      require 'pygments'

      args = params.dup
      args[:lexer] ||= language
      args[:options] ||= {}
      args[:options][:encoding] ||= 'utf-8'
      args[:options][:nowrap] ||= 'True'

      Pygments.highlight(code, args)
    end

    SIMON_HIGHLIGHT_OPT_MAP = {
      wrap: '-W',
      include_style: '-I',
      line_numbers: '-l',
    }.freeze

    # Runs the content through [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.html).
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @option params [String] :style The style to use
    #
    # @return [String] The colorized output
    def simon_highlight(code, language, params = {})
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

    # Wraps the element in <div class="CodeRay"><div class="code">
    def coderay_postprocess(_language, element)
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

    # Runs the content through [Rouge](https://github.com/jayferd/rouge/.
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @return [String] The colorized output
    def rouge(code, language, params = {})
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

    # Removes the double wrapping.
    #
    # Before:
    #
    #   <pre><code class="language-ruby"><pre class="highlight"><code>
    #
    # After:
    #
    #   <pre><code class="language-ruby highlight">
    def rouge_postprocess(_language, element)
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

    protected

    KNOWN_COLORIZERS = %i[coderay dummy pygmentize pygmentsrb simon_highlight rouge].freeze

    # Removes the first blank lines and any whitespace at the end.
    def strip(s)
      s.lines.drop_while { |line| line.strip.empty? }.join.rstrip
    end

    def highlight(code, language, params = {})
      colorizer = @colorizers[language.to_sym]
      if KNOWN_COLORIZERS.include?(colorizer)
        send(colorizer, code, language, params[colorizer] || {})
      else
        raise "I don’t know how to highlight code using the “#{colorizer}” colorizer"
      end
    end

    def highlight_postprocess(language, element)
      colorizer = @colorizers[language.to_sym]
      if KNOWN_COLORIZERS.include?(colorizer)
        sym = (colorizer.to_s + '_postprocess').to_sym
        if respond_to?(sym)
          send(sym, language, element)
        end
      else
        raise "I don’t know how to highlight code using the “#{colorizer}” colorizer"
      end
    end

    def check_availability(*cmd)
      piper = Nanoc::Extra::Piper.new(stdout: StringIO.new, stderr: StringIO.new)
      piper.run(cmd, nil)
    end
  end
end
