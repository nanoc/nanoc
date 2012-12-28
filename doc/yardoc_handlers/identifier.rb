class NanocIdentifierHandler < ::YARD::Handlers::Ruby::AttributeHandler

  # e.g. identifier :foo, :bar

  handles method_call(:identifier), method_call(:identifiers)
  namespace_only

  def process
    identifiers = statement.parameters(false).map { |param| param.jump(:ident)[0] }
    namespace['nanoc_identifiers'] = identifiers
  end

end

class NanocRegisterFilterHandler < ::YARD::Handlers::Ruby::AttributeHandler

  # e.g. Nanoc::Filter.register '::Nanoc::Filters::AsciiDoc', :asciidoc

  handles method_call(:register)
  namespace_only

  def process
    target = statement.jump(:const_path_ref)
    return if target != s(:const_path_ref, s(:var_ref, s(:const, "Nanoc")), s(:const, "Filter"))

    class_name = statement.jump(:string_literal).jump(:tstring_content)[0]
    identifier = statement.jump(:symbol_literal).jump(:ident)[0]

    obj = YARD::Registry.at(class_name.sub(/^::/, ''))
    obj['nanoc_identifiers'] ||= []
    obj['nanoc_identifiers'] << identifier
  end

end
