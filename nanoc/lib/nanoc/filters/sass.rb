# frozen_string_literal: true

module Nanoc::Filters
  module SassCommon
    REQUIRES = %w[sass nanoc/filters/sass/importer nanoc/filters/sass/functions].freeze

    def css(filter, rep, content, params)
      css, = render(filter, rep, content, params)
      css
    end

    def sourcemap(filter, rep, content, params)
      _, sourcemap = render(filter, rep, content, params)
      sourcemap
    end

    private

    def render(filter, rep, content, params = {})
      importer = Nanoc::Filters::SassCommon::Importer.new(filter)

      options = params.merge(
        load_paths: [importer, *params[:load_paths]&.reject { |p| p.is_a?(String) && %r{^content/} =~ p }],
        importer:,
        filename: rep.item.identifier.to_s,
        cache: false,
      )
      css_path = options.delete(:css_path) || filter.object_id.to_s
      sourcemap_path = options.delete(:sourcemap_path)
      if sourcemap_path == :inline
        sourcemap_path = Nanoc::Core::TempFilenameFactory.instance.create('sass_sourcemap')
        inline = true
      end

      engine = ::Sass::Engine.new(content, options)
      css, sourcemap = sourcemap_path ? engine.render_with_sourcemap(sourcemap_path) : engine.render

      if inline
        sourcemap = sourcemap&.to_json(css_uri: css_path)
        encoded = "data:application/json;base64,#{Base64.urlsafe_encode64(sourcemap)}"
        [css.gsub(%r{^/\*#\s+sourceMappingURL=\s*#{sourcemap_path}\s*\*/$}, "/*# sourceMappingURL=#{encoded} */")]
      else
        sourcemap = sourcemap&.to_json(css_path:, sourcemap_path:, type: params[:sources_content] ? :inline : :auto)
        sourcemap = sourcemap&.split("\n")&.reject { |l| l =~ /^\s*"file":\s*"#{filter.object_id}"\s*$/ }&.join("\n")
        [css, sourcemap]
      end
    end
  end

  class SassFilter < Nanoc::Filter
    identifier :sass

    include SassCommon
    requires(*SassCommon::REQUIRES)

    def run(content, params = {})
      css(self, @item_rep, content, params)
    end
  end

  class SassSourcemapFilter < Nanoc::Filter
    identifier :sass_sourcemap

    include SassCommon
    requires(*SassCommon::REQUIRES)

    def run(content, params = {})
      sourcemap(self, @item_rep, content, params)
    end
  end
end
