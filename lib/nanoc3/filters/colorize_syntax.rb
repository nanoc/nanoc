# encoding: utf-8

require 'nokogiri'
require 'stringio'
require 'open3'

module Nanoc3::Filters
  class ColorizeSyntax < Nanoc3::Filter

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
    # Currently, only the `:coderay` (http://coderay.rubychan.de/),
    # `:pygmentize` (http://pygments.org/, http://pygments.org/docs/cmdline/),
    # and `:simon_highlight`
    # (http://www.andre-simon.de/doku/highlight/en/highlight.html) colorizers
    # are implemented. Additional colorizer implementations are welcome!
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
    # @return [String] The filtered content
    def run(content, params={})
      # Take colorizers from parameters
      @colorizers = Hash.new(params[:default_colorizer] || DEFAULT_COLORIZER)
      (params[:colorizers] || {}).each_pair do |language, colorizer|
        @colorizers[language] = colorizer
      end

      # Determine syntax (HTML or XML)
      syntax = params[:syntax] || :html
      case syntax
      when :html
        klass = Nokogiri::HTML
      when :xml, :xhtml
        klass = Nokogiri::XML
      else
        raise RuntimeError, "unknown syntax: #{syntax.inspect} (expected :html or :xml)"
      end

      # Colorize
      doc = klass.fragment(content)
      doc.css('pre > code').each do |element|
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
          match = element.inner_text.match(/^#!([^\/][^\n]*)$/)
          language = match[1] if match
          element.content = element.content.sub(/^#!([^\/][^\n]*)$\n/, '') if language
        end

        # Give up if there is no hope left
        next if language.nil?

        # Highlight
        raw = strip(element.inner_text)
        highlighted_code = highlight(raw, language, params)
        element.inner_html = strip(highlighted_code)

        # Add class
        unless has_class
          klass = element['class'] || ''
          klass << ' ' unless [' ', nil].include?(klass[-1,1])
          klass << "language-#{language}"
          element['class'] = klass
        end
      end

      method = "to_#{syntax}".to_sym
      doc.send(method, :encoding => 'UTF-8')
    end

  private

    KNOWN_COLORIZERS = [ :coderay, :dummy, :pygmentize, :simon_highlight ]

    # Removes the first blank lines and any whitespace at the end.
    def strip(s)
      s.lines.drop_while { |line| line.strip.empty? }.join.rstrip
    end

    def highlight(code, language, params={})
      colorizer = @colorizers[language.to_sym]
      if KNOWN_COLORIZERS.include?(colorizer)
        send(colorizer, code, language, params[colorizer] || {})
      else
        raise RuntimeError, "I don’t know how to highlight code using the “#{colorizer}” colorizer"
      end
    end

    # Runs the code through [CodeRay](http://coderay.rubychan.de/).
    #
    # @api private
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @param [Hash] params Parameters to pass on to CodeRay
    #
    # @return [String] The colorized output
    def coderay(code, language, params={})
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
    def dummy(code, language, params={})
      code
    end

    # Runs the content through [pygmentize](http://pygments.org/docs/cmdline/),
    # the commandline frontend for [Pygments](http://pygments.org/).
    #
    # @api private
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @option params [String, Symbol] :encoding The encoding of the code block
    #
    # @return [String] The colorized output
    def pygmentize(code, language, params={})
      require 'systemu'
      check_availability('pygmentize', '-V')

      params[:encoding] ||= 'utf-8'
      params[:nowrap]   ||= 'True'

      # Build command
      cmd = [ 'pygmentize', '-l', language, '-f', 'html' ]
      cmd << '-O' << params.map { |k,v| "#{k}=#{v}" }.join(',') unless params.empty?

      # Run command
      stdout = StringIO.new
      systemu cmd, 'stdin' => code, 'stdout' => stdout

      # Get result
      stdout.rewind
      stdout.read
    end

    SIMON_HIGHLIGHT_OPT_MAP = {
        :wrap => '-W',
        :include_style => '-I',
        :line_numbers  => '-l',
    }

    # Runs the content through [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.html).
    #
    # @api private
    #
    # @param [String] code The code to colorize
    #
    # @param [String] language The language the code is written in
    #
    # @option params [String] :style The style to use
    #
    # @since 3.2.0
    def simon_highlight(code, language, params={})
      require 'systemu'

      check_availability('highlight', '--version')

      # Build command
      cmd = [ 'highlight', '--syntax', language, '--fragment' ]
      params.each do |key, value|
        if SIMON_HIGHLIGHT_OPT_MAP[key]
          cmd << SIMON_HIGHLIGHT_OPT_MAP[key]
        else
          # TODO allow passing other options
          case key
          when :style
            cmd << '--style' << params[:style]
          end
        end
      end

      # Run command
      stdout = StringIO.new
      systemu cmd, 'stdin' => code, 'stdout' => stdout

      # Get result
      stdout.rewind
      stdout.read
    end

    def check_availability(*cmd)
      systemu cmd
      raise "Could not spawn #{cmd.join(' ')}" if $?.exitstatus != 0
    end

  end
end
