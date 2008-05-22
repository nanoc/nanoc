require 'time'

class Hash

  # Cleans up the hash and returns the result. It performs the following
  # operations:
  #
  # * Values with keys ending in +_at+ and +_on+ are converted into +Time+ and
  #   and +Date+ objects, respectively
  # * All keys are converted to symbols
  # * Value strings 'true', 'false' and 'none' are converted into +true+,
  #   +false+ and +nil+, respectively
  def clean
    inject({}) do |hash, (key, value)|
      real_key = key.to_s
      if real_key =~ /_on$/
        hash.merge(key.to_sym => Date.parse(value))
      elsif real_key =~ /_at$/
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

  # Returns the hash where all keys are converted to strings.
  def stringify_keys
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_s => value.is_a?(Hash) ? value.stringify_keys : value)
    end
  end

end
