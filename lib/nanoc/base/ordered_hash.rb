# encoding: utf-8

# AUTHOR
#    jan molic /mig/at/1984/dot/cz/
#
# DESCRIPTION
#    Hash with preserved order and some array-like extensions
#    Public domain.
#
# THANKS
#    Andrew Johnson for his suggestions and fixes of Hash[],
#    merge, to_a, inspect and shift
class OrderedHash < ::Hash
  attr_accessor :order

  class << self
    def [](*args)
      hsh = OrderedHash.new
      if args[0].is_a?(Hash)
        hsh.replace args[0]
      elsif args.size.odd?
        raise ArgumentError, 'odd number of elements for Hash'
      else
        0.step(args.size - 1, 2) do |a|
          b = a + 1
          hsh[args[a]] = args[b]
        end
      end
      hsh
    end
  end

  def initialize(*a, &b)
    super
    @order = []
  end

  def store_only(a, b)
    store a, b
  end
  alias_method :orig_store, :store

  def store(a, b)
    @order.push a unless key? a
    super a, b
  end
  alias_method :[]=, :store

  def ==(other)
    return false if @order != other.order
    super other
  end

  def clear
    @order = []
    super
  end

  def delete(key)
    @order.delete key
    super
  end

  def each_key
    @order.each { |k| yield k }
    self
  end

  def each_value
    @order.each { |k| yield self[k] }
    self
  end

  def each
    @order.each { |k| yield k, self[k] }
    self
  end
  alias_method :each_pair, :each

  def delete_if
    @order.clone.each do |k|
      delete k if yield(k)
    end
    self
  end

  def values
    ary = []
    @order.each { |k| ary.push self[k] }
    ary
  end

  def keys
    @order
  end

  def first
    { @order.first => self[@order.first] }
  end

  def last
    { @order.last => self[@order.last] }
  end

  def invert
    hsh2 = {}
    @order.each { |k| hsh2[self[k]] = k }
    hsh2
  end

  def reject(&block)
    dup.delete_if(&block)
  end

  def reject!(&block)
    hsh2 = reject(&block)
    self == hsh2 ? nil : hsh2
  end

  def replace(hsh2)
    @order = hsh2.keys
    super hsh2
  end

  def shift
    key = @order.first
    key ? [key, delete(key)] : super
  end

  def unshift(k, v)
    if self.include? k
      false
    else
      @order.unshift k
      orig_store(k, v)
      true
    end
  end

  def push(k, v)
    if self.include? k
      false
    else
      @order.push k
      orig_store(k, v)
      true
    end
  end

  def pop
    key = @order.last
    key ? [key, delete(key)] : nil
  end

  def to_a
    ary = []
    each { |k, v| ary << [k, v] }
    ary
  end

  def to_s
    to_a.to_s
  end

  def inspect
    ary = []
    each { |k, v| ary << k.inspect + '=>' + v.inspect }
    '{' + ary.join(', ') + '}'
  end

  def update(hsh2)
    hsh2.each { |k, v| self[k] = v }
    self
  end
  alias_method :merge!, :update

  def merge(hsh2)
    dup update(hsh2)
  end

  def select
    ary = []
    each { |k, v| ary << [k, v] if yield k, v }
    ary
  end

  def class
    Hash
  end

  def __class__
    OrderedHash
  end

  attr_accessor 'to_yaml_style'
  def yaml_inline=(bool)
    if respond_to?('to_yaml_style')
      self.to_yaml_style = :inline
    else
      unless defined? @__yaml_inline_meth
        @__yaml_inline_meth =
        lambda do |opts|
          YAML.quick_emit(object_id, opts) do |emitter|
            emitter << '{ ' << map { |kv| kv.join ': ' }.join(', ') << ' }'
          end
        end
        class << self
          def to_yaml(opts = {})
            @__yaml_inline ? @__yaml_inline_meth[ opts ] : super
          rescue
            @to_yaml_style = :inline
            super
          end
        end
      end
    end
    @__yaml_inline = bool
  end

  def yaml_inline!
    self.yaml_inline = true
  end

  def each_with_index
    @order.each_with_index { |k, index| yield k, self[k], index }
    self
  end
end # class OrderedHash
