# encoding: utf-8 

module Nanoc::Filters

  class MultiMarkdownFilter < Nanoc::Filter
    identifier :multimarkdown
    type :text

    # Executes this filter. Parameters passed to this filter through `:opts`
    # will be passed to MultiMarkdown.
    #
    # @param [String] content The content to filter.
    #
    # @option params [Symbol] :opts ([]) A list of options for Multimarkdown.
    #  Example: opts: %w( --compatibility --to=latex --smart )
    #
    # @option params [Symbol] :path ("") The path to the directory containing 
    #   the `multimarkdown` executable. Use this when the executable is not in
    #   your PATH.
    #
    # @option params [Symbol] :debug (false) Set to true to enable debugging.
    #
    # @return [String] The filtered content
    def run(content, params = {})
      debug = params.fetch(:debug, false)
      cmd = [executable_from_params(params)]
      cmd.concat(params.fetch(:opts, []))
      odebug(cmd.join(' ')) if debug
      out = ''
      IO.popen(cmd, mode='r+') do |io|
        io.write content
        io.close_write # let the process know you've given it all the data
        out = io.read
      end
      odebug(out) if debug
      out
    end

  private

    def executable_from_params(params)
      mm = params.fetch(:path, nil)
      mm.nil? ? 'multimarkdown' : File.join(mm, 'multimarkdown')    
    end

    def odebug(msg)
      msg.each_line { |l| puts "\033[1;31mDEBUG:\033[0m #{l}" }
    end

  end

end
