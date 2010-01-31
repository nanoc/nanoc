# encoding: utf-8

module Nanoc3::CLI::Commands

  class Debug < Cri::Command

    def name
      'debug'
    end

    def aliases
      []
    end

    def short_desc
      'show debug information for this site'
    end

    def long_desc
      'Show information about all items, item representations and layouts ' \
      'in the current site.'
    end

    def usage
      "nanoc3 debug"
    end

    def option_definitions
      []
    end

    def run(options, arguments)
      # Make sure we are in a nanoc site directory
      print "Loading site data... "
      @base.require_site
      @base.site.load_data
      puts "done"
      puts

      # Get data
      items   = @base.site.items
      reps    = items.map { |i| i.reps }.flatten
      layouts = @base.site.layouts

      # Calculate prettification data
      identifier_length = items.map { |i| i.identifier.size }.max
      rep_name_length   = reps.map  { |r| r.name.size }.max

      # Print items
      puts '=== Items'
      puts
      items.sort_by { |i| i.identifier }.each do |item|
        item.reps.sort_by { |r| r.name.to_s }.each do |rep|
          # Print rep
          puts "* %s %s -> %s" % [
            fill(item.identifier, identifier_length, '· '),
            fill(rep.name.to_s,   rep_name_length,   ' '),
            rep.raw_path || '-'
          ]
        end
      end
      puts

      # Print layouts
      puts '=== Layouts'
      puts
      layouts.each do |layout|
        puts "* #{layout.identifier}"
      end
    end

  private

    # Returns a string that is exactly `length` long, starting with `text` and
    # filling up any unused space by repeating the string `filler`.
    def fill(text, length, filler)
      res = text.dup

      filler_length = (length - 1 - text.length)
      if filler_length >= 0
        # Append spacer to ensure alignment
        spacer_length = text.size % filler.length
        filler_length -= spacer_length
        res << ' ' * (spacer_length + 1)

        # Append leader
        res << filler*(filler_length/filler.length)
      end

      res
    end

  end

end
