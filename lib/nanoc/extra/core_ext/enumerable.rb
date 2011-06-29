# encoding: utf-8

module Enumerable

  if !Enumerable.instance_methods.include?('group_by')

    # Returns a hash, which keys are evaluated result from the block, and
    # values are arrays of elements in enum corresponding to the key. This
    # method is provided for backward compatibility with Ruby 1.8.6 and lower,
    # since {#group_by} is only available in 1.8.7 and higher.
    #
    # @yieldparam [Object] obj The object to classify
    #
    # @return [Hash]
    #
    # @example Grouping integers by rest by division through 3
    #
    #   (1..6).group_by { |i| i % 3 }
    #   # => { 0 => [3, 6], 1 => [1, 4], 2 => [2, 5] }
    def group_by
      groups = {}
      each do |item|
        key = yield(item)

        groups[key] ||= []
        groups[key] << item
      end
      groups
    end

  end

end
