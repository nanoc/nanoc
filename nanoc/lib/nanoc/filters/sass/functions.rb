# frozen_string_literal: true

module ::Sass::Script::Functions
  def nanoc(string, params)
    assert_type string, :String
    assert_type params, :Hash
    result = options[:importer].filter.instance_eval(string.value)
    case result
    when TrueClass, FalseClass
      bool(result)
    when Array
      list(result, :comma)
    when Hash
      map(result)
    when nil
      null
    when Numeric
      number(result)
    else
      params['unquote'] ? unquoted_string(result) : quoted_string(result)
    end
  end
  declare :nanoc, [:string], var_kwargs: true
end
