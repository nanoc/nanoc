# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.

def html_escape(a_string)
  a_string.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
end
alias h html_escape
