class String

  def wrap_and_indent(width, indentation)
    # Split into paragraphs
    paragraphs = self.split("\n").map { |p| p.strip }.reject { |p| p == '' }

    # Wrap and indent each paragraph
    paragraphs.map do |paragraph|
      # Initialize
      lines = []
      line = ''

      # Split into words
      paragraph.split(/\s/).each do |word|
        # Begin new line if it's too long
        if (line + ' ' + word).length >= width
          lines << line
          line = ''
        end

        # Add word to line
        line += (line == '' ? '' : ' ' ) + word
      end
      lines << line

      # Join lines
      lines.map { |l| ' '*indentation + l }.join("\n")
    end.join("\n\n")
  end

end
