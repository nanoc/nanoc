# encoding: utf-8

module Nanoc3::Filters
  class ColorizeSyntax < Nanoc3::Filter

    # The default colorizer to use for a language if the colorizer for that
    # language is not overridden.
    DEFAULT_COLORIZER = :coderay

    # Syntax-highlights code blocks in the given content. Code blocks should
    # be enclosed in `pre` elements that contain a `code` element. The code
    # element should have a class starting with `language-` and followed by
    # the programming language, as specified by HTML5.
    #
    # Options for individual colorizers will be taken from the {#run}
    # options’ value for the given colorizer. For example, if the filter is
    # invoked with a `:coderay => coderay_options_hash` option, the
    # `coderay_options_hash` hash will be passed to the CodeRay colorizer.
    #
    # Currently, only the `:coderay` and `:pygmentize` colorizers are
    # implemented. Additional colorizer implementations are welcome!
    #
    # @example Content that will be highlighted
    #
    #     <pre><code class="language-ruby">
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
    # @option params [Hash] :colorizers (DEFAULT_COLORIZER) A hash containing
    #   a mapping of programming languages (symbols, not strings) onto
    #   colorizers (symbols).
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'nokogiri'

      # Take colorizers from parameters
      @colorizers = Hash.new(DEFAULT_COLORIZER)
      (params[:colorizers] || {}).each_pair do |language, colorizer|
        @colorizers[language] = colorizer
      end

      # Colorize
      doc = Nokogiri::HTML.fragment(content)
      doc.css('pre > code[class*="language-"]').each do |element|
        # Get language
        match = element['class'].match(/(^| )language-([^ ]+)/)
        next if match.nil?
        language = match[2]

        # Highlight
        highlighted_code = highlight(element.inner_text, language, params)
        element.inner_html = highlighted_code
      end

      doc.to_html(:encoding => 'UTF-8')
    end

  private

    KNOWN_COLORIZERS = [ :coderay, :dummy, :pygmentize ]

    def highlight(code, language, params={})
      colorizer = @colorizers[language.to_sym]
      if KNOWN_COLORIZERS.include?(colorizer)
        send(colorizer, code, language, params[colorizer] || {})
      else
        raise RuntimeError, "I don’t know how to highlight code using the “#{colorizer}” colorizer"
      end
    end

    def coderay(code, language, params={})
      require 'coderay'

      ::CodeRay.scan(code, language).html(params)
    end

    def dummy(code, language, params={})
      code
    end

    def pygmentize(code, language, params={})
      IO.popen("pygmentize -l #{language} -f html", "r+") do |io|
        io.write(code)
        io.close_write
        highlighted_code = io.read

        doc = Nokogiri::HTML.fragment(highlighted_code)
        return doc.xpath('./div[@class="highlight"]/pre').inner_html
      end
    end

  end
end
