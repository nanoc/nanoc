# encoding: utf-8

module Nanoc3::Filters
  class ColorizeSyntax < Nanoc3::Filter

    DEFAULT_COLORIZER = :coderay

    def run(content, params={})
      require 'nokogiri'

      # Take colorizers from parameters
      @colorizers = Hash.new(DEFAULT_COLORIZER)
      (params[:colorizers] || {}).each_pair do |language, colorizer|
        @colorizers[language] = colorizer
      end

      # Colorize
      doc = Nokogiri::HTML.fragment(content)
      doc.css('pre > code[class*="lang-"]').each do |element|
        # Get language
        match = element['class'].match(/(^| )lang-([^ ]+)/)
        next if match.nil?
        language = match[2]

        # Highlight
        highlighted_code = highlight(element.inner_text, language, params)
        element.inner_html = highlighted_code
      end

      doc.to_s
    end

  private

    KNOWN_COLORIZERS = [ :coderay, :dummy, :pygmentize ]

    def highlight(code, language, params={})
      colorizer = @colorizers[language]
      if KNOWN_COLORIZERS.include?(colorizer)
        send(colorizer, code, language, params[colorizer])
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
        return io.read
      end
    end

  end
end
