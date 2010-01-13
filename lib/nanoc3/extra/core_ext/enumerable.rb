# encoding: utf-8

module Nanoc3::Extra::EnumerableExtensions

  module GroupBy

    # Returns a hash, which keys are evaluated result from the block, and
    # values are arrays of elements in enum corresponding to the key.
    #
    # Provided for backward compatibility with Ruby 1.8.6 and lower, since
    # group_by is only available in 1.8.7 and higher.
    #
    #   (1..6).group_by {|i| i%3}   #=> {0=>[3, 6], 1=>[1, 4], 2=>[2, 5]}
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

module Enumerable
  if !Enumerable.instance_methods.include?('group_by')
    include Nanoc3::Extra::EnumerableExtensions::GroupBy
  end
end
