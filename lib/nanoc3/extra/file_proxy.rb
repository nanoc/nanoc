# encoding: utf-8

module Nanoc3::Extra

  # @deprecated Create a File instance directly and use that instead.
  class FileProxy

    instance_methods.each { |m| undef_method m unless m =~ /^__/ || m.to_s == 'object_id' }

    @@deprecation_warning_shown = false

    def initialize(path)
      @path = path
    end

    def respond_to?(meth)
      File.instance_methods.any? { |m| m == meth.to_s || m == meth.to_sym }
    end

    def method_missing(sym, *args, &block)
      if !@@deprecation_warning_shown
        $stderr.puts 'WARNING: The :file attribute is deprecated and will be removed in a future version of nanoc. Instead of using this :file attribute, consider manually creating a File object when it’s needed, using the :content_filename, :meta_filename or :filename attributes.'
        @@deprecation_warning_shown = true
      end

      File.open(@path, 'r') { |io| io.__send__(sym, *args, &block) }
    end

  end

end
