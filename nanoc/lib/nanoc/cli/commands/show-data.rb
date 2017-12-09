# frozen_string_literal: true

usage 'show-data'
aliases :debug
summary 'show data in this site'
description <<~EOS
  Show information about all items, item representations and layouts in the
  current site, along with dependency information.
EOS

module Nanoc::CLI::Commands
  class ShowData < ::Nanoc::CLI::CommandRunner
    def run
      site = load_site
      res = Nanoc::Int::Compiler.new_for(site).run_until_precompiled

      items                = site.items
      layouts              = site.layouts
      reps                 = res.fetch(:reps)
      dependency_store     = res.fetch(:dependency_store)
      outdatedness_checker = res.fetch(:outdatedness_checker)

      # Print data
      print_item_dependencies(items, dependency_store)
      print_item_rep_paths(items, reps)
      print_item_rep_outdatedness(items, outdatedness_checker, reps)
      print_layouts(layouts, outdatedness_checker)
    end

    protected

    def sorted_with_prev(objects)
      prev = nil
      objects.sort_by(&:identifier).each do |object|
        yield(object, prev)
        prev = object
      end
    end

    def sorted_reps_with_prev(items, reps)
      prev = nil
      items.sort_by(&:identifier).each do |item|
        reps[item].sort_by { |r| r.name.to_s }.each do |rep|
          yield(rep, prev)
          prev = rep
        end
      end
    end

    def print_header(title)
      header = '=' * 78
      header[3..(title.length + 5)] = " #{title} "

      puts
      puts header
      puts
    end

    def print_item_dependencies(items, dependency_store)
      print_header('Item dependencies')

      puts 'Legend:'
      puts '  r = dependency on raw content'
      puts '  a = dependency on attributes'
      puts '  c = dependency on compiled content'
      puts '  p = dependency on the path'
      puts

      sorter =
        lambda do |dep|
          case dep
          when Nanoc::Int::Document
            dep.from.identifier.to_s
          else
            ''
          end
        end

      sorted_with_prev(items) do |item, prev|
        puts if prev
        puts "item #{item.identifier} depends on:"
        dependencies =
          dependency_store
          .dependencies_causing_outdatedness_of(item)
          .sort_by(&sorter)
        dependencies.each do |dep|
          pred = dep.from

          type =
            case pred
            when Nanoc::Int::Layout
              'layout'
            when Nanoc::Int::Item
              'item'
            when Nanoc::Int::Configuration
              'config'
            when Nanoc::Int::ItemCollection
              'items'
            when Nanoc::Int::LayoutCollection
              'layouts'
            else
              raise Nanoc::Int::Errors::InternalInconsistency, "unexpected pred type #{pred}"
            end

          pred_identifier =
            case pred
            when Nanoc::Int::Document
              pred.identifier.to_s
            when Nanoc::Int::Configuration
              nil
            when Nanoc::Int::IdentifiableCollection
              case dep.props.raw_content
              when true
                'matching any'
              else
                "matching any of #{dep.props.raw_content.sort.join(', ')}"
              end
            else
              raise Nanoc::Int::Errors::InternalInconsistency, "unexpected pred type #{pred}"
            end

          if pred
            puts "  [ #{format '%6s', type} ] (#{dep.props}) #{pred_identifier}"
          else
            puts '  ( removed item )'
          end
        end
        puts '  (nothing)' if dependencies.empty?
      end
    end

    def print_item_rep_paths(items, reps)
      print_header('Item representation paths')

      sorted_reps_with_prev(items, reps) do |rep, prev|
        puts if prev
        puts "item #{rep.item.identifier}, rep #{rep.name}:"
        if rep.raw_paths.empty?
          puts '  (not written)'
        end
        length = rep.raw_paths.keys.map { |s| s.to_s.length }.max
        rep.raw_paths.each do |snapshot_name, raw_paths|
          raw_paths.each do |raw_path|
            puts format("  [ %-#{length}s ] %s", snapshot_name, raw_path)
          end
        end
      end
    end

    def print_item_rep_outdatedness(items, outdatedness_checker, reps)
      print_header('Item representation outdatedness')

      sorted_reps_with_prev(items, reps) do |rep, prev|
        puts if prev
        puts "item #{rep.item.identifier}, rep #{rep.name}:"
        print_outdatedness_reasons_for(rep, outdatedness_checker)
      end
    end

    def print_layouts(layouts, outdatedness_checker)
      print_header('Layouts')

      sorted_with_prev(layouts) do |layout, prev|
        puts if prev
        puts "layout #{layout.identifier}:"
        print_outdatedness_reasons_for(layout, outdatedness_checker)
      end
    end

    def print_outdatedness_reasons_for(obj, outdatedness_checker)
      reasons = outdatedness_checker.outdatedness_reasons_for(obj)
      if reasons.any?
        puts '  is outdated:'
        reasons.each do |reason|
          puts "    - #{reason.message}"
        end
      else
        puts '  is not outdated'
      end
    end
  end
end

runner Nanoc::CLI::Commands::ShowData
