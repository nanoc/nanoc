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

    def run
      self.require_site

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

  protected

    def sorted_with_prev(objects)
      prev = nil
      objects.sort_by { |o| o.identifier }.each do |object|
        yield(object, prev)
        prev = object
      end
    end

    def sorted_reps_with_prev(items)
      prev = nil
      items.sort_by { |i| i.identifier }.each do |item|
        item.reps.sort_by { |r| r.name.to_s }.each do |rep|
          yield(rep, prev)
          prev = rep
        end
      end
    end

    def print_header(title)
      header = '=' * 78
      header[3..(title.length+5)] = " #{title} "

      puts
      puts header
      puts
    end

    def print_item_dependencies(items, dependency_tracker)
      self.print_header('Item dependencies')

      self.sorted_with_prev(items) do |item, prev|
        puts if prev
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

      self.sorted_reps_with_prev(items) do |rep, prev|
        puts if prev
        puts "item #{rep.item.identifier}, rep #{rep.name}:"
        if rep.raw_paths.empty?
          puts "  (not written)"
        end
        length = rep.raw_paths.keys.map { |s| s.to_s.length }.max
        rep.raw_paths.each do |snapshot_name, raw_path|
          puts "  [ %-#{length}s ] %s" % [ snapshot_name, raw_path ]
        end
      end
    end

    def print_item_rep_outdatedness(items, compiler)
      self.print_header('Item representation outdatedness')

      self.sorted_reps_with_prev(items) do |rep, prev|
        puts if prev
        puts "item #{rep.item.identifier}, rep #{rep.name}:"
        outdatedness_reason = compiler.outdatedness_checker.outdatedness_reason_for(rep)
        if outdatedness_reason
          puts "  is outdated: #{outdatedness_reason.message}"
        else
          puts "  is not outdated"
        end
      end
    end

    def print_layouts(layouts, compiler)
      self.print_header('Layouts')

      self.sorted_with_prev(layouts) do |layout, prev|
        puts if prev
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

  end

end

runner Nanoc::CLI::Commands::ShowData
