def init
  super
  return if sections.empty?

  sections[1].unshift(:nonpublic)
end

def nonpublic
  return unless object.has_tag?(:private)
  erb(:nonpublic)
end
