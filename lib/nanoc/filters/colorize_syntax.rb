# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class ColorizeSyntax < Nanoc::Filter
    identifier :colorize_syntax

    requires 'nokogiri', 'stringio', 'open3'

    DEFAULT_COLORIZER = :coderay

    ExtractedLanguage = Struct.new(:language, :from_class)

    def run(content, params = {})
      Nanoc::Extra::JRubyNokogiriWarner.check_and_warn

      @colorizers = colorizers_from_params(params)

      syntax = params.fetch(:syntax, :html)
      parser = parser_for(syntax)

      # Colorize
      doc = parse(content, parser, params.fetch(:is_fullpage, false))
      selector = params[:outside_pre] ? 'code' : 'pre > code'
      doc.css(selector).each do |element|
        # Get language
        extracted_language = extract_language(element)

        # Give up if there is no hope left
        next unless extracted_language

        # Highlight
        raw = strip(element.inner_text)
        highlighted_code = highlight(raw, extracted_language.language, params)
        element.children = parse_fragment(parser, strip(highlighted_code))

        # Add language-something class
        unless extracted_language.from_class
          klass = element['class'] || String.new
          klass << ' ' unless [' ', nil].include?(klass[-1, 1])
          klass << "language-#{extracted_language.language}"
          element['class'] = klass
        end

        highlight_postprocess(extracted_language.language, element.parent)
      end

      serialize(doc, syntax)
    end

    def extract_language(element)
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

      language ? ExtractedLanguage.new(language, has_class) : nil
    end

    def colorizers_from_params(params)
      colorizers = Hash.new(params[:default_colorizer] || DEFAULT_COLORIZER)
      (params[:colorizers] || {}).each_pair do |language, colorizer|
        colorizers[language] = colorizer
      end
      colorizers
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

    protected

    # Removes the first blank lines and any whitespace at the end.
    def strip(s)
      s.lines.drop_while { |line| line.strip.empty? }.join.rstrip
    end

    def colorizer_name_for(language)
      @colorizers[language.to_sym]
    end

    def colorizer_named(name)
      colorizer = Colorizers::Abstract.named(name.to_sym)
      unless colorizer
        raise "I don’t know how to highlight code using the “#{name}” colorizer"
      end
      colorizer
    end

    def highlight(code, language, params = {})
      colorizer_name = colorizer_name_for(language)
      colorizer = colorizer_named(colorizer_name)
      colorizer.new.process(code, language, params[colorizer_name] || {})
    end

    def highlight_postprocess(language, element)
      colorizer_name = colorizer_name_for(language)
      colorizer = colorizer_named(colorizer_name)
      colorizer.new.postprocess(language, element)
    end
  end
end

require_relative 'colorize_syntax/colorizers'
