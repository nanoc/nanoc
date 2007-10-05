class Hash
  # Cleans up the hash and returns the result. It performs the following
  # operations:
  #
  # * Values with keys ending in _at and _on are converted into Times and
  #   Dates, respectively
  # * All keys are converted to symbols
  # * Value strings 'true', 'false', and 'none' are converted into
  #   true, false, and nil, respectively
  def clean
    symbolize_keys.inject({}) do |hash, (key, value)|
      if key.to_s =~ /_on$/
        hash.merge(key => Date.parse(value))
      elsif key.to_s =~ /_at$/
        hash.merge(key => Time.parse(value))
      elsif value == 'true'
        hash.merge(key => true)
      elsif value == 'false'
        hash.merge(key => false)
      elsif value == 'none'
        hash.merge(key => nil)
      else
        hash.merge(key => value)
      end
    end
  end

  # Converts all keys in the hash to symbols and returns the result
  def symbolize_keys
    inject({}) do |hash, (key, value)|
      new_value = value.respond_to?(:symbolize_keys) ? value.symbolize_keys : value
      hash.merge({ key.to_sym => new_value })
    end
  end

  # Converts all keys in the hash to strings and returns the result
  def stringify_keys
    inject({}) do |hash, (key, value)|
      new_value = value.respond_to?(:stringify_keys) ? value.stringify_keys : value
      hash.merge({ key.to_s => new_value })
    end
  end
end
