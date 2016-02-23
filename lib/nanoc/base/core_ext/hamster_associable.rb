# @api private
module ::Hamster::Associable
  # Useful function that is missing from Hamser. Similar to Ruby 2.3’s #dig and Clojure’s get-in.
  def get_in(*key_path)
    if key_path.empty?
      raise ArgumentError, 'must have at least one key in path'
    end

    key = key_path[0]

    if key_path.size == 1
      fetch(key, nil)
    else
      fetch(key, Hamster::EmptyHash).get_in(*key_path.drop(1))
    end
  end
end
