module Nanoc::Extra::HashExtensions

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
    # Skip irrelevant keys
    hash = self.reject { |k,v| k == :file }

    # Split keys
    hashes = { :builtin => {}, :custom => {} }
    hash.each_pair do |key, value|
      kind = Nanoc::Page::DEFAULTS.include?(key) || Nanoc::Asset::DEFAULTS.include?(key) ? :builtin : :custom
      hashes[kind][key] = value
    end

    # Dump and clean hashes
    dumps = { :builtin => '', :custom => '' }
    [ :builtin, :custom ].each do |kind|
      if hashes[kind].keys.empty?
        dumps[kind] = "\n"
      else
        raw_dump = YAML.dump(hashes[kind].stringify_keys)
        dumps[kind] = raw_dump.split('---')[1].gsub("\n\n", "\n")
      end
    end

    # Built composite YAML file
    '# Built-in' +
    dumps[:builtin] +
    "\n" +
    '# Custom' +
    dumps[:custom]
  end

end

class Hash
  include Nanoc::Extra::HashExtensions
end
