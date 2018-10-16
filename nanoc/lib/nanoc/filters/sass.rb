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
        importer: importer,
        filename: rep.item.identifier.to_s,
        cache: false,
      )
      sourcemap_path = options.delete(:sourcemap_path)

      engine = ::Sass::Engine.new(content, options)
      css, sourcemap = sourcemap_path ? engine.render_with_sourcemap(sourcemap_path) : engine.render
      [css, sourcemap&.to_json(css_uri: rep.path, type: rep.path.nil? ? :inline : :auto)]
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
