module Nanoc
  class DotNotationHash

    def initialize(hash, params={})
      @hash       = hash
      @is_builtin = params[:is_builtin]
      @page_proxy = params[:page_proxy]
    end

    def [](key)
      # Conver to a symbol and strip the ? if present
      real_key = key.to_s
      real_key = real_key[0..-2] if real_key.ends_with?('?')
      real_key = real_key.to_sym

      # Get value
      res = @hash[real_key]
      res = @page_proxy[real_key] if res.nil? and @is_builtin

      # Return (dotnotationized if necessary) hash
      res.is_a?(Hash) ? DotNotationHash.new(res) : res
    end

    def method_missing(method, *args)
      self[method.to_sym]
    end

  end
end
