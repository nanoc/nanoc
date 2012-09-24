# encoding: utf-8

usage       'show-data'
aliases     :debug
summary     'show data in this site'
description <<-EOS
Show information about all items, item representations and layouts in the
current site, along with dependency information.
EOS

module Nanoc::CLI::Commands

  class ShowData < ::Nanoc::CLI::CommandRunner

    def print_header(title)
      header = '=' * 78
      header[3..(title.length+5)] = " #{title} "

      puts
      puts header
      puts
    end

    def print_item_dependencies(items, dependency_tracker)
      self.print_header('Item dependencies')

      is_first = true
      items.sort_by { |i| i.identifier }.each do |item|
        puts unless is_first
        is_first = false
        puts "item #{item.identifier} depends on:"
        predecessors = dependency_tracker.objects_causing_outdatedness_of(item).sort_by { |i| i ? i.identifier : '' }
        predecessors.each do |pred|
          if pred
            puts "  [ #{format '%6s', pred.type} ] #{pred.identifier}"
          else
            puts "  ( removed item )"
          end
        end
        puts "  (nothing)" if predecessors.empty?
      end
    end

    def print_item_rep_paths(items)
      self.print_header('Item representation paths')

      is_first = true
      items.sort_by { |i| i.identifier }.each do |item|
        puts unless is_first
        is_first = false
        item.reps.sort_by { |r| r.name.to_s }.each do |rep|
          puts "item #{item.identifier}, rep #{rep.name}:"
          if rep.raw_paths.empty?
            puts "  (not written)"
          end
          length = rep.raw_paths.keys.map { |s| s.to_s.length }.max
          rep.raw_paths.each do |snapshot_name, raw_path|
            puts "  [ %-#{length}s ] %s" % [ snapshot_name, raw_path ]
          end
        end
      end
    end

    def print_item_rep_outdatedness(items, compiler)
      self.print_header('Item representation outdatedness')

      is_first = true
      items.sort_by { |i| i.identifier }.each do |item|
        puts unless is_first
        is_first = false
        item.reps.sort_by { |r| r.name.to_s }.each do |rep|
          puts "item #{item.identifier}, rep #{rep.name}:"
          outdatedness_reason = compiler.outdatedness_checker.outdatedness_reason_for(rep)
          if outdatedness_reason
            puts "  is outdated: #{outdatedness_reason.message}"
          else
            puts "  is not outdated"
          end
        end
      end
    end

    def print_layouts(layouts, compiler)
      self.print_header('Layouts')

      is_first = true
      layouts.sort_by { |l| l.identifier }.each do |layout|
        puts unless is_first
        is_first = false
        puts "layout #{layout.identifier}:"
        outdatedness_reason = compiler.outdatedness_checker.outdatedness_reason_for(layout)
        if outdatedness_reason
          puts "  is outdated: #{outdatedness_reason.message}"
        else
          puts "  is not outdated"
        end
        puts
      end
    end

    def run
      # Make sure we are in a nanoc site directory
      print "Loading site data... "
      self.require_site
      puts "done"

      # Get data
      items     = self.site.items
      item_reps = items.map { |i| i.reps }.flatten
      layouts   = self.site.layouts

      # Get dependency tracker
      compiler = self.site.compiler
      compiler.load
      dependency_tracker = compiler.dependency_tracker

      # Print data
      self.print_item_dependencies(items, dependency_tracker)
      self.print_item_rep_paths(items)
      self.print_item_rep_outdatedness(items, compiler)
      self.print_layouts(layouts, compiler)
    end

  end

end

runner Nanoc::CLI::Commands::ShowData
