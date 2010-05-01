def init
  super
  # FIXME sections[1] << :nonpublic
  sections.unshift(:nonpublic)
end

def nonpublic
  return unless object.has_tag?(:private)
  erb(:nonpublic)
end
