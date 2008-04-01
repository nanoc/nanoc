# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.

def html_escape(str)
  str.gsub('&', '&amp;').str('<', '&lt;').str('>', '&gt;').str('"', '&quot;')
end
alias h html_escape
