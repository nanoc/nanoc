# encoding: utf-8

class ::Sass::Importers::Filesystem

  alias_method :_orig_find, :_find

  def _find(dir, name, options)
    # Find filename
    full_filename, _syntax = ::Sass::Util.destructure(find_real_file(dir, name, options))
    return nil if full_filename.nil?

    # Create dependency
    filter = options[:nanoc_current_filter]
    item = filter.imported_filename_to_item(full_filename)
    filter.depend_on([ item ]) unless item.nil?

    # Call original _find
    _orig_find(dir, name, options)
  end

end
