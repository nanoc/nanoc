class Hash

  # Converts this hash into YAML format, splitting the YAML output into a
  # 'builtin' and a 'custom' section. A key that is present in
  # Nanoc::Page::DEFAULTS will be considered a 'default' key; all other keys
  # will be put in the 'Custom' section.
  #
  # For example, the hash:
  #
  #   {
  #     :title       => 'My Cool Page',
  #     :filters_pre => [ 'foo', 'bar' ]
  #   }
  #
  # will be converted into:
  #
  #   # Built-in
  #   filters_pre: [ 'foo', 'bar' ]
  #    
  #   # Custom
  #   title: 'My Cool Page'
  #
  # as +filters_pre+ is considered a 'default' key while +title+ is not.
  def to_split_yaml
    # Get list of built-in keys
    builtin_keys = Nanoc::Page::DEFAULTS

    # Stringify keys
    hash = self.reject { |k,v| k == :file }.stringify_keys

    # Split keys
    builtin_hash = hash.reject { |k,v| !builtin_keys.include?(k) }
    custom_hash  = hash.reject { |k,v| builtin_keys.include?(k) }

    # Convert to YAML
    # FIXME this is a hack, plz clean up
    '# Built-in' +
    (builtin_hash.keys.empty? ? "\n" : YAML.dump(builtin_hash).split('---')[1]) +
    "\n" +
    '# Custom' +
    (custom_hash.keys.empty? ? "\n" : YAML.dump(custom_hash).split('---')[1])
  end

end
