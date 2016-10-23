module ::Nanoc::Extra::Checking::Checks
  # @api private
  class HTML < ::Nanoc::Extra::Checking::Check
    identifier :html

    ACCEPTABLE_INVALID_TAG_HTML5_REGEX =
      /Tag (article|aside|audio|bdi|bdo|canvas|data|datalist|details|dialog|figcaption|figure|footer|header|hgroup|keygen|main|mark|menu|menuitem|meter|nav|output|picture|progress|rp|rt|ruby|section|slot|source|summary|template|time|track|video|wbr) invalid/i

    ACCEPTABLE_INVALID_TAG_SVG_REGEX =
      /Tag (a|altGlyph|altGlyphDef|altGlyphItem|animate|animateColor|animateMotion|animateTransform|circle|clipPath|color-profile|cursor|defs|desc|ellipse|feBlend|feColorMatrix|feComponentTransfer|feComposite|feConvolveMatrix|feDiffuseLighting|feDisplacementMap|feDistantLight|feFlood|feFuncA|feFuncB|feFuncG|feFuncR|feGaussianBlur|feImage|feMerge|feMergeNode|feMorphology|feOffset|fePointLight|feSpecularLighting|feSpotLight|feTile|feTurbulence|filter|font-face-format|font-face-name|font-face-src|font-face-uri|font-face|font|foreignObject|g|glyph|glyphRef|hkern|image|line|linearGradient|marker|mask|metadata|missing-glyph|mpath|path|pattern|polygon|polyline|radialGradient|rect|script|set|stop|style|svg|switch|symbol|text|textPath|title|tref|tspan|use|view|vkern) invalid/i

    ACCEPTABLE_INVALID_TAG_REGEX =
      Regexp.union(ACCEPTABLE_INVALID_TAG_HTML5_REGEX, ACCEPTABLE_INVALID_TAG_SVG_REGEX)

    def run
      require 'nokogiri'

      filenames = output_filenames.select { |f| File.extname(f) == '.html' }
      filenames.each do |filename|
        doc = Nokogiri::HTML(File.read(filename), &:strict)
        doc.errors.each do |error|
          next if error.message =~ ACCEPTABLE_INVALID_TAG_REGEX
          add_issue("#{error.message} (line #{error.line}, column #{error.column})", subject: filename)
        end
      end
    end
  end
end
