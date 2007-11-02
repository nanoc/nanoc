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
    stringify_keys.inject({}) do |hash, (key, value)|
      if key =~ /_on$/
        hash.merge(key.to_sym => Date.parse(value))
      elsif key =~ /_at$/
        hash.merge(key.to_sym => Time.parse(value))
      elsif value == 'true'
        hash.merge(key.to_sym => true)
      elsif value == 'false'
        hash.merge(key.to_sym => false)
      elsif value == 'none'
        hash.merge(key.to_sym => nil)
      elsif value.is_a?(Hash)
        hash.merge(key.to_sym => value.clean)
      else
        hash.merge(key.to_sym => value)
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
