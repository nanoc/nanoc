# encoding: utf-8

module Nanoc3::Extra

  # A FileProxy is a proxy for a File object. It is used to prevent a File
  # object from being created until it is actually necessary.
  #
  # For example, a site with a few thousand items would fail to compile
  # because the massive amount of file descriptors necessary, but the file
  # proxy will make sure the File object is not created until it is used.
  class FileProxy

    instance_methods.each { |m| undef_method m unless m =~ /^__/ || m.to_s == 'object_id' }

    # Creates a new file proxy for the given path. This is similar to
    # creating a File object with the same path, except that the File object
    # will not be created until it is accessed.
    def initialize(path)
      @path = path
    end

    # Returns true if File instances respond to the given method; false if
    # they do not.
    def respond_to?(meth)
      File.instance_methods.any? { |m| m == meth.to_s || m == meth.to_sym }
    end

    # Makes sure all method calls are relayed to a File object, which will
    # be created right before the method call takes place and destroyed
    # right after.
    def method_missing(sym, *args, &block)
      File.open(@path, 'r') { |io| io.__send__(sym, *args, &block) }
    end

  end

end
