#--
# MIME::Types for Ruby
# Version 1.15
#
# Copyright (c) 2002 - 2004 Austin Ziegler
#
# $Id: types.rb,v 1.4 2006/02/12 21:27:22 austin Exp $
#
# The ChangeLog contains all details on revisions.
#++

# The namespace for MIME applications, tools, and libraries.
module MIME
  # Reflects a MIME Content-Type which is in invalid format (e.g., it isn't
  # in the form of type/subtype).
  class InvalidContentType < RuntimeError; end

  # The definition of one MIME content-type.
  #
  # == Usage
  #  require 'mime/types'
  #
  #  plaintext = MIME::Types['text/plain']
  #  print plaintext.media_type           # => 'text'
  #  print plaintext.sub_type             # => 'plain'
  #
  #  puts plaintext.extensions.join(" ")  # => 'asc txt c cc h hh cpp'
  #
  #  puts plaintext.encoding              # => 8bit
  #  puts plaintext.binary?               # => false
  #  puts plaintext.ascii?                # => true
  #  puts plaintext == 'text/plain'       # => true
  #  puts MIME::Type.simplified('x-appl/x-zip') # => 'appl/zip'
  #
  class Type
    VERSION = '1.15'

    include Comparable

    MEDIA_TYPE_RE = %r{([-\w.+]+)/([-\w.+]*)}o #:nodoc:
    UNREG_RE      = %r{[Xx]-}o #:nodoc:
    ENCODING_RE   = %r{(?:base64|7bit|8bit|quoted\-printable)}o #:nodoc:
    PLATFORM_RE   = %r|#{RUBY_PLATFORM}|o #:nodoc:

    SIGNATURES    = %w(application/pgp-keys application/pgp
                       application/pgp-signature application/pkcs10
                       application/pkcs7-mime application/pkcs7-signature
                       text/vcard) #:nodoc:

    IANA_URL      = "http://www.iana.org/assignments/media-types/%s/%s"
    RFC_URL       = "http://rfc-editor.org/rfc/rfc%s.txt"
    DRAFT_URL     = "http://datatracker.ietf.org/public/idindex.cgi?command=id_details&filename=%s"
    LTSW_URL      = "http://www.ltsw.se/knbase/internet/%s.htp"
    CONTACT_URL   = "http://www.iana.org/assignments/contact-people.htm#%s"

    # Returns +true+ if the simplified type matches the current 
    def like?(other)
      if other.respond_to?(:simplified)
        @simplified == other.simplified
      else
        @simplified == Type.simplified(other)
      end
    end

    # Compares the MIME::Type against the exact content type or the
    # simplified type (the simplified type will be used if comparing against
    # something that can be treated as a String with #to_s).
    def <=>(other) #:nodoc:
      if other.respond_to?(:content_type)
        @content_type.downcase <=> other.content_type.downcase
      elsif other.respond_to?(:to_s)
        @simplified <=> Type.simplified(other.to_s)
      else
        @content_type.downcase <=> other.downcase
      end
    end

    # Returns +true+ if the other object is a MIME::Type and the content
    # types match.
    def eql?(other) #:nodoc:
      other.kind_of?(MIME::Type) and self == other
    end

    # Returns the whole MIME content-type string.
    #
    #   text/plain        => text/plain
    #   x-chemical/x-pdb  => x-chemical/x-pdb
    attr_reader :content_type
    # Returns the media type of the simplified MIME type.
    #
    #   text/plain        => text
    #   x-chemical/x-pdb  => chemical
    attr_reader :media_type
    # Returns the media type of the unmodified MIME type.
    #
    #   text/plain        => text
    #   x-chemical/x-pdb  => x-chemical
    attr_reader :raw_media_type
    # Returns the sub-type of the simplified MIME type.
    #
    #   text/plain        => plain
    #   x-chemical/x-pdb  => pdb
    attr_reader :sub_type
    # Returns the media type of the unmodified MIME type.
    # 
    #   text/plain        => plain
    #   x-chemical/x-pdb  => x-pdb
    attr_reader :raw_sub_type
    # The MIME types main- and sub-label can both start with <tt>x-</tt>,
    # which indicates that it is a non-registered name. Of course, after
    # registration this flag can disappear, adds to the confusing
    # proliferation of MIME types. The simplified string has the <tt>x-</tt>
    # removed and are translated to lowercase.
    #
    #   text/plain        => text/plain
    #   x-chemical/x-pdb  => chemical/pdb
    attr_reader :simplified
    # The list of extensions which are known to be used for this MIME::Type.
    # Non-array values will be coerced into an array with #to_a. Array
    # values will be flattened and +nil+ values removed.
    attr_accessor :extensions
    remove_method :extensions= ;
    def extensions=(ext) #:nodoc:
      @extensions = ext.to_a.flatten.compact
    end

    # The encoding (7bit, 8bit, quoted-printable, or base64) required to
    # transport the data of this content type safely across a network, which
    # roughly corresponds to Content-Transfer-Encoding. A value of +nil+ or
    # <tt>:default</tt> will reset the #encoding to the #default_encoding
    # for the MIME::Type. Raises ArgumentError if the encoding provided is
    # invalid.
    #
    # If the encoding is not provided on construction, this will be either
    # 'quoted-printable' (for text/* media types) and 'base64' for eveything
    # else.
    attr_accessor :encoding
    remove_method :encoding= ;
    def encoding=(enc) #:nodoc:
      if enc.nil? or enc == :default
        @encoding = self.default_encoding
      elsif enc =~ ENCODING_RE
        @encoding = enc
      else
        raise ArgumentError, "The encoding must be nil, :default, base64, 7bit, 8bit, or quoted-printable."
      end
    end

    # The regexp for the operating system that this MIME::Type is specific
    # to.
    attr_accessor :system
    remove_method :system= ; 
    def system=(os) #:nodoc:
      if os.nil? or os.kind_of?(Regexp)
        @system = os
      else
        @system = %r|#{os}|
      end
    end
    # Returns the default encoding for the MIME::Type based on the media
    # type.
    attr_reader :default_encoding
    remove_method :default_encoding
    def default_encoding
      (@media_type == 'text') ? 'quoted-printable' : 'base64'
    end

    # Returns the media type or types that should be used instead of this
    # media type, if it is obsolete. If there is no replacement media type,
    # or it is not obsolete, +nil+ will be returned.
    attr_reader :use_instead
    remove_method :use_instead
    def use_instead
      return nil unless @obsolete
      @use_instead
    end

    # Returns +true+ if the media type is obsolete.
    def obsolete?
      @obsolete ? true : false
    end
    # Sets the obsolescence indicator for this media type.
    attr_writer :obsolete

    # The documentation for this MIME::Type. Documentation about media
    # types will be found on a media type definition as a comment.
    # Documentation will be found through #docs.
    attr_accessor :docs
    remove_method :docs= ;
    def docs=(d)
      if d
        a = d.scan(%r{use-instead:#{MEDIA_TYPE_RE}})

        if a.empty?
          @use_instead = nil
        else
          @use_instead = a.map { |el| "#{el[0]}/#{el[1]}" }
        end
      end
    end

    # The encoded URL list for this MIME::Type. See #urls for 
    attr_accessor :url
    # The decoded URL list for this MIME::Type.
    # The special URL value IANA will be translated into:
    #   http://www.iana.org/assignments/media-types/<mediatype>/<subtype>
    #
    # The special URL value RFC### will be translated into:
    #   http://www.rfc-editor.org/rfc/rfc###.txt
    #
    # The special URL value DRAFT:name will be translated into:
    #   https://datatracker.ietf.org/public/idindex.cgi?
    #       command=id_detail&filename=<name>
    #
    # The special URL value LTSW will be translated into:
    #   http://www.ltsw.se/knbase/internet/<mediatype>.htp
    #
    # The special URL value [token] will be translated into:
    #   http://www.iana.org/assignments/contact-people.htm#<token>
    #
    # These values will be accessible through #url, which always returns an
    # array.
    def urls
      @url.map { |el|
        case el
        when %r{^IANA$}
          IANA_URL % [ @media_type, @sub_type ]
        when %r{^RFC(\d+)$}
          RFC_URL % $1
        when %r{^DRAFT:(.+)$}
          DRAFT_URL % $1
        when %r{^LTSW$}
          LTSW_URL % @media_type
        when %r{^\[([^\]]+)\]}
          CONTACT_URL % $1
        else
          el
        end
      }
    end

    class << self
      # The MIME types main- and sub-label can both start with <tt>x-</tt>,
      # which indicates that it is a non-registered name. Of course, after
      # registration this flag can disappear, adds to the confusing
      # proliferation of MIME types. The simplified string has the
      # <tt>x-</tt> removed and are translated to lowercase.
      def simplified(content_type)
        matchdata = MEDIA_TYPE_RE.match(content_type)

        if matchdata.nil?
          simplified = nil
        else
          media_type = matchdata.captures[0].downcase.gsub(UNREG_RE, '')
          subtype = matchdata.captures[1].downcase.gsub(UNREG_RE, '')
          simplified = "#{media_type}/#{subtype}"
        end
        simplified
      end

      # Creates a MIME::Type from an array in the form of:
      #   [type-name, [extensions], encoding, system]
      #
      # +extensions+, +encoding+, and +system+ are optional.
      #
      #   MIME::Type.from_array("application/x-ruby", ['rb'], '8bit')
      #   MIME::Type.from_array(["application/x-ruby", ['rb'], '8bit'])
      #
      # These are equivalent to:
      #
      #   MIME::Type.new('application/x-ruby') do |t|
      #     t.extensions  = %w(rb)
      #     t.encoding    = '8bit'
      #   end
      def from_array(*args) #:yields MIME::Type.new:
        # Dereferences the array one level, if necessary.
        args = args[0] if args[0].kind_of?(Array)

        if args.size.between?(1, 8)
          m = MIME::Type.new(args[0]) do |t|
            t.extensions  = args[1] if args.size > 1
            t.encoding    = args[2] if args.size > 2
            t.system      = args[3] if args.size > 3
            t.obsolete    = args[4] if args.size > 4
            t.docs        = args[5] if args.size > 5
            t.url         = args[6] if args.size > 6
            t.registered  = args[7] if args.size > 7
          end
          yield m if block_given?
        else
          raise ArgumentError, "Array provided must contain between one and eight elements."
        end
        m
      end

      # Creates a MIME::Type from a hash. Keys are case-insensitive,
      # dashes may be replaced with underscores, and the internal Symbol
      # of the lowercase-underscore version can be used as well. That is,
      # Content-Type can be provided as content-type, Content_Type,
      # content_type, or :content_type.
      #
      # Known keys are <tt>Content-Type</tt>,
      # <tt>Content-Transfer-Encoding</tt>, <tt>Extensions</tt>, and
      # <tt>System</tt>.
      #
      #   MIME::Type.from_hash('Content-Type' => 'text/x-yaml',
      #                        'Content-Transfer-Encoding' => '8bit',
      #                        'System' => 'linux',
      #                        'Extensions' => ['yaml', 'yml'])
      #
      # This is equivalent to:
      #
      #   MIME::Type.new('text/x-yaml') do |t|
      #     t.encoding    = '8bit'
      #     t.system      = 'linux'
      #     t.extensions  = ['yaml', 'yml']
      #   end
      def from_hash(hash) #:yields MIME::Type.new:
        type = {}
        hash.each_pair do |k, v| 
          type[k.to_s.tr('-A-Z', '_a-z').to_sym] = v
        end

        m = MIME::Type.new(type[:content_type]) do |t|
          t.extensions  = type[:extensions]
          t.encoding    = type[:content_transfer_encoding]
          t.system      = type[:system]
          t.obsolete    = type[:obsolete]
          t.docs        = type[:docs]
          t.url         = type[:url]
          t.registered  = type[:registered]
        end

        yield m if block_given?
        m
      end

      # Essentially a copy constructor.
      #
      #   MIME::Type.from_mime_type(plaintext)
      #
      # is equivalent to:
      #
      #   MIME::Type.new(plaintext.content_type.dup) do |t|
      #     t.extensions  = plaintext.extensions.dup
      #     t.system      = plaintext.system.dup
      #     t.encoding    = plaintext.encoding.dup
      #   end
      def from_mime_type(mime_type) #:yields the new MIME::Type:
        m = MIME::Type.new(mime_type.content_type.dup) do |t|
          t.extensions = mime_type.extensions.dup
          t.system = mime_type.system.dup
          t.encoding = mime_type.encoding.dup
        end

        yield m if block_given?
      end
    end

    # Builds a MIME::Type object from the provided MIME Content Type value
    # (e.g., 'text/plain' or 'applicaton/x-eruby'). The constructed object
    # is yielded to an optional block for additional configuration, such as
    # associating extensions and encoding information.
    def initialize(content_type) #:yields self:
      matchdata = MEDIA_TYPE_RE.match(content_type)

      if matchdata.nil?
        raise InvalidContentType, "Invalid Content-Type provided ('#{content_type}')"
      end

      @content_type = content_type
      @raw_media_type = matchdata.captures[0]
      @raw_sub_type = matchdata.captures[1]

      @simplified = MIME::Type.simplified(@content_type)
      matchdata = MEDIA_TYPE_RE.match(@simplified)
      @media_type = matchdata.captures[0]
      @sub_type = matchdata.captures[1]

      self.extensions   = nil
      self.encoding     = :default
      self.system       = nil
      self.registered   = true

      yield self if block_given?
    end

    # MIME content-types which are not regestered by IANA nor defined in
    # RFCs are required to start with <tt>x-</tt>. This counts as well for
    # a new media type as well as a new sub-type of an existing media
    # type. If either the media-type or the content-type begins with
    # <tt>x-</tt>, this method will return +false+.
    def registered?
      if (@raw_media_type =~ UNREG_RE) || (@raw_sub_type =~ UNREG_RE)
        false
      else
        @registered
      end
    end
    attr_writer :registered #:nodoc:

    # MIME types can be specified to be sent across a network in particular
    # formats. This method returns +true+ when the MIME type encoding is set
    # to <tt>base64</tt>.
    def binary?
      @encoding == 'base64'
    end

    # MIME types can be specified to be sent across a network in particular
    # formats. This method returns +false+ when the MIME type encoding is
    # set to <tt>base64</tt>.
    def ascii?
      not binary?
    end

    # Returns +true+ when the simplified MIME type is in the list of known
    # digital signatures.
    def signature?
      SIGNATURES.include?(@simplified.downcase)
    end

    # Returns +true+ if the MIME::Type is specific to an operating system.
    def system?
      not @system.nil?
    end

    # Returns +true+ if the MIME::Type is specific to the current operating
    # system as represented by RUBY_PLATFORM.
    def platform?
      system? and (RUBY_PLATFORM =~ @system)
    end

    # Returns +true+ if the MIME::Type specifies an extension list,
    # indicating that it is a complete MIME::Type.
    def complete?
      not @extensions.empty?
    end

    # Returns the MIME type as a string.
    def to_s
      @content_type
    end

    # Returns the MIME type as a string for implicit conversions.
    def to_str
      @content_type
    end

    # Returns the MIME type as an array suitable for use with
    # MIME::Type.from_array.
    def to_a
      [ @content_type, @extensions, @encoding, @system, @obsolete, @docs,
        @url, registered? ]
    end

    # Returns the MIME type as an array suitable for use with
    # MIME::Type.from_hash.
    def to_hash
      { 'Content-Type'              => @content_type,
        'Content-Transfer-Encoding' => @encoding,
        'Extensions'                => @extensions,
        'System'                    => @system,
        'Obsolete'                  => @obsolete,
        'Docs'                      => @docs,
        'URL'                       => @url,
        'Registered'                => registered?,
      }
    end
  end

  # = MIME::Types
  # MIME types are used in MIME-compliant communications, as in e-mail or
  # HTTP traffic, to indicate the type of content which is transmitted.
  # MIME::Types provides the ability for detailed information about MIME
  # entities (provided as a set of MIME::Type objects) to be determined and
  # used programmatically. There are many types defined by RFCs and vendors,
  # so the list is long but not complete; don't hesitate to ask to add
  # additional information. This library follows the IANA collection of MIME
  # types (see below for reference).
  #
  # == Description
  # MIME types are used in MIME entities, as in email or HTTP traffic. It is
  # useful at times to have information available about MIME types (or,
  # inversely, about files). A MIME::Type stores the known information about
  # one MIME type.
  #
  # == Usage
  #  require 'mime/types'
  #
  #  plaintext = MIME::Types['text/plain']
  #  print plaintext.media_type           # => 'text'
  #  print plaintext.sub_type             # => 'plain'
  #
  #  puts plaintext.extensions.join(" ")  # => 'asc txt c cc h hh cpp'
  #
  #  puts plaintext.encoding              # => 8bit
  #  puts plaintext.binary?               # => false
  #  puts plaintext.ascii?                # => true
  #  puts plaintext.obsolete?             # => false
  #  puts plaintext.registered?           # => true
  #  puts plaintext == 'text/plain'       # => true
  #  puts MIME::Type.simplified('x-appl/x-zip') # => 'appl/zip'
  #
  # This module is built to conform to the MIME types of RFCs 2045 and 2231.
  # It follows the official IANA registry at
  # http://www.iana.org/assignments/media-types/ and
  # ftp://ftp.iana.org/assignments/media-types with some unofficial types
  # added from the the collection at
  # http://www.ltsw.se/knbase/internet/mime.htp
  #
  # This is originally based on Perl MIME::Types by Mark Overmeer.
  #
  # = Author
  # Copyright:: Copyright (c) 2002 - 2006 by Austin Ziegler
  #             <austin@rubyforge.org>
  # Version::   1.15
  # Based On::  Perl
  #             MIME::Types[http://search.cpan.org/author/MARKOV/MIME-Types-1.15/MIME/Types.pm],
  #             Copyright (c) 2001 - 2005 by Mark Overmeer
  #             <mimetypes@overmeer.net>.
  # Licence::   Ruby's, Perl Artistic, or GPL version 2 (or later)
  # See Also::  http://www.iana.org/assignments/media-types/
  #             http://www.ltsw.se/knbase/internet/mime.htp
  #
  class Types
    # The released version of Ruby MIME::Types
    VERSION  = '1.15'

      # The data version.
    attr_reader :data_version

    def initialize(data_version = nil)
      @type_variants    = Hash.new { |h, k| h[k] = [] }
      @extension_index  = Hash.new { |h, k| h[k] = [] }
    end

    def add_type_variant(mime_type) #:nodoc:
      @type_variants[mime_type.simplified] << mime_type
    end

    def index_extensions(mime_type) #:nodoc:
      mime_type.extensions.each { |ext| @extension_index[ext] << mime_type }
    end

    @__types__ = self.new(VERSION)

    # Returns a list of MIME::Type objects, which may be empty. The optional
    # flag parameters are :complete (finds only complete MIME::Type objects)
    # and :platform (finds only MIME::Types for the current platform). It is
    # possible for multiple matches to be returned for either type (in the
    # example below, 'text/plain' returns two values -- one for the general
    # case, and one for VMS systems.
    #
    #   puts "\nMIME::Types['text/plain']"
    #   MIME::Types['text/plain'].each { |t| puts t.to_a.join(", ") }
    #
    #   puts "\nMIME::Types[/^image/, :complete => true]"
    #   MIME::Types[/^image/, :complete => true].each do |t|
    #     puts t.to_a.join(", ")
    #   end
    def [](type_id, flags = {})
      if type_id.kind_of?(Regexp)
        matches = []
        @type_variants.each_key do |k|
          matches << @type_variants[k] if k =~ type_id
        end
        matches.flatten!
      elsif type_id.kind_of?(MIME::Type)
        matches = [type_id]
      else
        matches = @type_variants[MIME::Type.simplified(type_id)]
      end

      matches.delete_if { |e| not e.complete? } if flags[:complete]
      matches.delete_if { |e| not e.platform? } if flags[:platform]
      matches
    end

    # Return the list of MIME::Types which belongs to the file based on its
    # filename extension. If +platform+ is +true+, then only file types that
    # are specific to the current platform will be returned.
    #
    #   puts "MIME::Types.type_for('citydesk.xml')
    #     => "#{MIME::Types.type_for('citydesk.xml')}"
    #   puts "MIME::Types.type_for('citydesk.gif')
    #     => "#{MIME::Types.type_for('citydesk.gif')}"
    def type_for(filename, platform = false)
      ext = filename.chomp.downcase.gsub(/.*\./o, '')
      list = @extension_index[ext]
      list.delete_if { |e| not e.platform? } if platform
      list
    end

    # A synonym for MIME::Types.type_for
    def of(filename, platform = false)
      type_for(filename, platform)
    end

    # Add one or more MIME::Type objects to the set of known types. Each
    # type should be experimental (e.g., 'application/x-ruby'). If the type
    # is already known, a warning will be displayed.
    #
    # <b>Please inform the maintainer of this module when registered types
    # are missing.</b>
    def add(*types)
      types.each do |mime_type|
        if @type_variants.include?(mime_type.simplified)
          if @type_variants[mime_type.simplified].include?(mime_type)
            warn "Type #{mime_type} already registered as a variant of #{mime_type.simplified}."
          end
        end
        add_type_variant(mime_type)
        index_extensions(mime_type)
      end
    end

    class <<self
      def add_type_variant(mime_type) #:nodoc:
        @__types__.add_type_variant(mime_type)
      end

      def index_extensions(mime_type) #:nodoc:
        @__types__.index_extensions(mime_type)
      end

      # Returns a list of MIME::Type objects, which may be empty. The
      # optional flag parameters are :complete (finds only complete
      # MIME::Type objects) and :platform (finds only MIME::Types for the
      # current platform). It is possible for multiple matches to be
      # returned for either type (in the example below, 'text/plain' returns
      # two values -- one for the general case, and one for VMS systems.
      #
      #   puts "\nMIME::Types['text/plain']"
      #   MIME::Types['text/plain'].each { |t| puts t.to_a.join(", ") }
      #
      #   puts "\nMIME::Types[/^image/, :complete => true]"
      #   MIME::Types[/^image/, :complete => true].each do |t|
      #     puts t.to_a.join(", ")
      #   end
      def [](type_id, flags = {})
        @__types__[type_id, flags]
      end

      # Return the list of MIME::Types which belongs to the file based on
      # its filename extension. If +platform+ is +true+, then only file
      # types that are specific to the current platform will be returned.
      #
      #   puts "MIME::Types.type_for('citydesk.xml')
      #     => "#{MIME::Types.type_for('citydesk.xml')}"
      #   puts "MIME::Types.type_for('citydesk.gif')
      #     => "#{MIME::Types.type_for('citydesk.gif')}"
      def type_for(filename, platform = false)
        @__types__.type_for(filename, platform)
      end

      # A synonym for MIME::Types.type_for
      def of(filename, platform = false)
        @__types__.type_for(filename, platform)
      end

      # Add one or more MIME::Type objects to the set of known types. Each
      # type should be experimental (e.g., 'application/x-ruby'). If the
      # type is already known, a warning will be displayed.
      #
      # <b>Please inform the maintainer of this module when registered types
      # are missing.</b>
      def add(*types)
        @__types__.add(*types)
      end
    end
  end
end

# Build the type list
data_mime_type = <<MIME_TYPES
# What follows is the compiled list of known media types, IANA-registered
# ones first, one per line.
#
#   [*][!][os:]mt/st[<ws>@ext][<ws>:enc][<ws>'url-list][<ws>=docs]
#
# == *
# An unofficial MIME type. This should be used if an only if the MIME type
# is not properly specified.
#
# == !
# An obsolete MIME type.
#
# == os:
# Platform-specific MIME type definition.
#
# == mt
# The media type.
#
# == st
# The media subtype.
#
# == <ws>@ext
# The list of comma-separated extensions.
#
# == <ws>:enc
# The encoding.
#
# == <ws>'url-list
# The list of comma-separated URLs.
#
# == <ws>=docs
# The documentation string.
#
# That is, everything except the media type and the subtype is optional.
#
# -- Austin Ziegler, 2006.02.12

  # Registered: application/*
!application/xhtml-voice+xml 'DRAFT:draft-mccobb-xplusv-media-type
application/CSTAdata+xml 'IANA,[Ecma International Helpdesk]
application/EDI-Consent 'RFC1767
application/EDI-X12 'RFC1767
application/EDIFACT 'RFC1767
application/activemessage 'IANA,[Shapiro]
application/andrew-inset 'IANA,[Borenstein]
application/applefile :base64 'IANA,[Faltstrom]
application/atom+xml 'RFC4287
application/atomicmail 'IANA,[Borenstein]
application/batch-SMTP 'RFC2442
application/beep+xml 'RFC3080
application/cals-1840 'RFC1895
application/ccxml+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/cnrp+xml 'RFCCNRP
application/commonground 'IANA,[Glazer]
application/conference-info+xml 'DRAFT:draft-ietf-sipping-conference-package
application/cpl+xml 'RFC3880
application/csta+xml 'IANA,[Ecma International Helpdesk]
application/cybercash 'IANA,[Eastlake]
application/dca-rft 'IANA,[Campbell]
application/dec-dx 'IANA,[Campbell]
application/dialog-info+xml 'DRAFT:draft-ietf-sipping-dialog-package
application/dicom 'RFC3240
application/dns 'RFC4027
application/dvcs 'RFC3029
application/ecmascript 'DRAFT:draft-hoehrmann-script-types
application/epp+xml 'RFC3730
application/eshop 'IANA,[Katz]
application/fastinfoset 'IANA,[ITU-T ASN.1 Rapporteur]
application/fastsoap 'IANA,[ITU-T ASN.1 Rapporteur]
application/fits 'RFC4047
application/font-tdpfr @pfr 'RFC3073
application/http 'RFC2616
application/hyperstudio @stk 'IANA,[Domino]
application/iges 'IANA,[Parks]
application/im-iscomposing+xml 'RFC3994
application/index 'RFC2652
application/index.cmd 'RFC2652
application/index.obj 'RFC2652
application/index.response 'RFC2652
application/index.vnd 'RFC2652
application/iotp 'RFC2935
application/ipp 'RFC2910
application/isup 'RFC3204
application/javascript 'DRAFT:draft-hoehrmann-script-types
application/kpml-request+xml 'DRAFT:draft-ietf-sipping-kpml
application/kpml-response+xml 'DRAFT:draft-ietf-sipping-kpml
application/mac-binhex40 @hqx :8bit 'IANA,[Faltstrom]
application/macwriteii 'IANA,[Lindner]
application/marc 'RFC2220
application/mathematica 'IANA,[Van Nostern]
application/mbox 'DRAFT:draft-hall-mime-app-mbox
application/mikey 'RFC3830
application/mp4 'DRAFT:draft-lim-mpeg4-mime
application/mpeg4-generic 'RFC3640
application/mpeg4-iod 'DRAFT:draft-lim-mpeg4-mime
application/mpeg4-iod-xmt 'DRAFT:draft-lim-mpeg4-mime
application/msword @doc,dot :base64 'IANA,[Lindner]
application/news-message-id 'RFC1036,[Spencer]
application/news-transmission 'RFC1036,[Spencer]
application/nss 'IANA,[Hammer]
application/ocsp-request 'RFC2560
application/ocsp-response 'RFC2560
application/octet-stream @bin,dms,lha,lzh,exe,class,ani,pgp :base64 'RFC2045,RFC2046
application/oda @oda 'RFC2045,RFC2046
application/ogg @ogg 'RFC3534
application/parityfec 'RFC3009
application/pdf @pdf :base64 'RFC3778
application/pgp-encrypted :7bit 'RFC3156
application/pgp-keys :7bit 'RFC3156
application/pgp-signature @sig :base64 'RFC3156
application/pidf+xml 'IANA,RFC3863
application/pkcs10 @p10 'RFC2311
application/pkcs7-mime @p7m,p7c 'RFC2311
application/pkcs7-signature @p7s 'RFC2311
application/pkix-cert @cer 'RFC2585
application/pkix-crl @crl 'RFC2585
application/pkix-pkipath @pkipath 'DRAFT:draft-ietf-tls-rfc3546bis
application/pkixcmp @pki 'RFC2510
application/pls+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/poc-settings+xml 'DRAFT:draft-garcia-sipping-poc-isb-am
application/postscript @ai,eps,ps :8bit 'RFC2045,RFC2046
application/prs.alvestrand.titrax-sheet 'IANA,[Alvestrand]
application/prs.cww @cw,cww 'IANA,[Rungchavalnont]
application/prs.nprend @rnd,rct 'IANA,[Doggett]
application/prs.plucker 'IANA,[Janssen]
application/qsig 'RFC3204
application/rdf+xml @rdf 'RFC3870
application/reginfo+xml 'RFC3680
application/remote-printing 'IANA,RFC1486,[Rose]
application/resource-lists+xml 'DRAFT:draft-ietf-simple-xcap-list-usage
application/riscos 'IANA,[Smith]
application/rlmi+xml 'DRAFT:draft-ietf-simple-event-list
application/rls-services+xml 'DRAFT:draft-ietf-simple-xcap-list-usage
application/rtf @rtf 'IANA,[Lindner]
application/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission
application/samlassertion+xml 'IANA,[OASIS Security Services Technical Committee (SSTC)]
application/samlmetadata+xml 'IANA,[OASIS Security Services Technical Committee (SSTC)]
application/sbml+xml 'RFC3823
application/sdp 'RFC2327
application/set-payment 'IANA,[Korver]
application/set-payment-initiation 'IANA,[Korver]
application/set-registration 'IANA,[Korver]
application/set-registration-initiation 'IANA,[Korver]
application/sgml @sgml 'RFC1874
application/sgml-open-catalog @soc 'IANA,[Grosso]
application/shf+xml 'RFC4194
application/sieve @siv 'RFC3028
application/simple-filter+xml 'DRAFT:draft-ietf-simple-filter-format
application/simple-message-summary 'RFC3842
application/slate 'IANA,[Crowley]
application/soap+fastinfoset 'IANA,[ITU-T ASN.1 Rapporteur]
application/soap+xml 'RFC3902
application/spirits-event+xml 'RFC3910
application/srgs 'DRAFT:draft-froumentin-voice-mediatypes
application/srgs+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/ssml+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/timestamp-query 'RFC3161
application/timestamp-reply 'RFC3161
application/tve-trigger 'IANA,[Welsh]
application/vemmi 'RFC2122
application/vnd.3M.Post-it-Notes 'IANA,[O'Brien]
application/vnd.3gpp.pic-bw-large @plb 'IANA,[Meredith]
application/vnd.3gpp.pic-bw-small @psb 'IANA,[Meredith]
application/vnd.3gpp.pic-bw-var @pvb 'IANA,[Meredith]
application/vnd.3gpp.sms @sms 'IANA,[Meredith]
application/vnd.FloGraphIt 'IANA,[Floersch]
application/vnd.Kinar @kne,knp,sdf 'IANA,[Thakkar]
application/vnd.Mobius.DAF 'IANA,[Kabayama]
application/vnd.Mobius.DIS 'IANA,[Kabayama]
application/vnd.Mobius.MBK 'IANA,[Devasia]
application/vnd.Mobius.MQY 'IANA,[Devasia]
application/vnd.Mobius.MSL 'IANA,[Kabayama]
application/vnd.Mobius.PLC 'IANA,[Kabayama]
application/vnd.Mobius.TXF 'IANA,[Kabayama]
application/vnd.Quark.QuarkXPress @qxd,qxt,qwd,qwt,qxl,qxb :8bit 'IANA,[Scheidler]
application/vnd.RenLearn.rlprint 'IANA,[Wick]
application/vnd.accpac.simply.aso 'IANA,[Leow]
application/vnd.accpac.simply.imp 'IANA,[Leow]
application/vnd.acucobol 'IANA,[Lubin]
application/vnd.acucorp @atc,acutc :7bit 'IANA,[Lubin]
application/vnd.adobe.xfdf @xfdf 'IANA,[Perelman]
application/vnd.aether.imp 'IANA,[Moskowitz]
application/vnd.amiga.ami @ami 'IANA,[Blumberg]
application/vnd.apple.installer+xml 'IANA,[Bierman]
application/vnd.audiograph 'IANA,[Slusanschi]
application/vnd.autopackage 'IANA,[Hearn]
application/vnd.blueice.multipass @mpm 'IANA,[Holmstrom]
application/vnd.bmi 'IANA,[Gotoh]
application/vnd.businessobjects 'IANA,[Imoucha]
application/vnd.cinderella @cdy 'IANA,[Kortenkamp]
application/vnd.claymore 'IANA,[Simpson]
application/vnd.commerce-battelle 'IANA,[Applebaum]
application/vnd.commonspace 'IANA,[Chandhok]
application/vnd.contact.cmsg 'IANA,[Patz]
application/vnd.cosmocaller @cmc 'IANA,[Dellutri]
application/vnd.criticaltools.wbs+xml @wbs 'IANA,[Spiller]
application/vnd.ctc-posml 'IANA,[Kohlhepp]
application/vnd.cups-postscript 'IANA,[Sweet]
application/vnd.cups-raster 'IANA,[Sweet]
application/vnd.cups-raw 'IANA,[Sweet]
application/vnd.curl @curl 'IANA,[Byrnes]
application/vnd.cybank 'IANA,[Helmee]
application/vnd.data-vision.rdz @rdz 'IANA,[Fields]
application/vnd.dna 'IANA,[Searcy]
application/vnd.dpgraph 'IANA,[Parker]
application/vnd.dreamfactory @dfac 'IANA,[Appleton]
application/vnd.dxr 'IANA,[Duffy]
application/vnd.ecdis-update 'IANA,[Buettgenbach]
application/vnd.ecowin.chart 'IANA,[Olsson]
application/vnd.ecowin.filerequest 'IANA,[Olsson]
application/vnd.ecowin.fileupdate 'IANA,[Olsson]
application/vnd.ecowin.series 'IANA,[Olsson]
application/vnd.ecowin.seriesrequest 'IANA,[Olsson]
application/vnd.ecowin.seriesupdate 'IANA,[Olsson]
application/vnd.enliven 'IANA,[Santinelli]
application/vnd.epson.esf 'IANA,[Hoshina]
application/vnd.epson.msf 'IANA,[Hoshina]
application/vnd.epson.quickanime 'IANA,[Gu]
application/vnd.epson.salt 'IANA,[Nagatomo]
application/vnd.epson.ssf 'IANA,[Hoshina]
application/vnd.ericsson.quickcall 'IANA,[Tidwell]
application/vnd.eudora.data 'IANA,[Resnick]
application/vnd.fdf 'IANA,[Zilles]
application/vnd.ffsns 'IANA,[Holstage]
application/vnd.fints 'IANA,[Hammann]
application/vnd.fluxtime.clip 'IANA,[Winter]
application/vnd.framemaker 'IANA,[Wexler]
application/vnd.fsc.weblaunch @fsc :7bit 'IANA,[D.Smith]
application/vnd.fujitsu.oasys 'IANA,[Togashi]
application/vnd.fujitsu.oasys2 'IANA,[Togashi]
application/vnd.fujitsu.oasys3 'IANA,[Okudaira]
application/vnd.fujitsu.oasysgp 'IANA,[Sugimoto]
application/vnd.fujitsu.oasysprs 'IANA,[Ogita]
application/vnd.fujixerox.ddd 'IANA,[Onda]
application/vnd.fujixerox.docuworks 'IANA,[Taguchi]
application/vnd.fujixerox.docuworks.binder 'IANA,[Matsumoto]
application/vnd.fut-misnet 'IANA,[Pruulmann]
application/vnd.genomatix.tuxedo @txd 'IANA,[Frey]
application/vnd.grafeq 'IANA,[Tupper]
application/vnd.groove-account 'IANA,[Joseph]
application/vnd.groove-help 'IANA,[Joseph]
application/vnd.groove-identity-message 'IANA,[Joseph]
application/vnd.groove-injector 'IANA,[Joseph]
application/vnd.groove-tool-message 'IANA,[Joseph]
application/vnd.groove-tool-template 'IANA,[Joseph]
application/vnd.groove-vcard 'IANA,[Joseph]
application/vnd.hbci @hbci,hbc,kom,upa,pkd,bpd 'IANA,[Hammann]
application/vnd.hcl-bireports 'IANA,[Serres]
application/vnd.hhe.lesson-player @les 'IANA,[Jones]
application/vnd.hp-HPGL @plt,hpgl 'IANA,[Pentecost]
application/vnd.hp-PCL 'IANA,[Pentecost]
application/vnd.hp-PCLXL 'IANA,[Pentecost]
application/vnd.hp-hpid 'IANA,[Gupta]
application/vnd.hp-hps 'IANA,[Aubrey]
application/vnd.httphone 'IANA,[Lefevre]
application/vnd.hzn-3d-crossword 'IANA,[Minnis]
application/vnd.ibm.MiniPay 'IANA,[Herzberg]
application/vnd.ibm.afplinedata 'IANA,[Buis]
application/vnd.ibm.electronic-media @emm 'IANA,[Tantlinger]
application/vnd.ibm.modcap 'IANA,[Hohensee]
application/vnd.ibm.rights-management @irm 'IANA,[Tantlinger]
application/vnd.ibm.secure-container @sc 'IANA,[Tantlinger]
application/vnd.informix-visionary 'IANA,[Gales]
application/vnd.intercon.formnet 'IANA,[Gurak]
application/vnd.intertrust.digibox 'IANA,[Tomasello]
application/vnd.intertrust.nncp 'IANA,[Tomasello]
application/vnd.intu.qbo 'IANA,[Scratchley]
application/vnd.intu.qfx 'IANA,[Scratchley]
application/vnd.ipunplugged.rcprofile @rcprofile 'IANA,[Ersson]
application/vnd.irepository.package+xml @irp 'IANA,[Knowles]
application/vnd.is-xpr 'IANA,[Natarajan]
application/vnd.japannet-directory-service 'IANA,[Fujii]
application/vnd.japannet-jpnstore-wakeup 'IANA,[Yoshitake]
application/vnd.japannet-payment-wakeup 'IANA,[Fujii]
application/vnd.japannet-registration 'IANA,[Yoshitake]
application/vnd.japannet-registration-wakeup 'IANA,[Fujii]
application/vnd.japannet-setstore-wakeup 'IANA,[Yoshitake]
application/vnd.japannet-verification 'IANA,[Yoshitake]
application/vnd.japannet-verification-wakeup 'IANA,[Fujii]
application/vnd.jisp @jisp 'IANA,[Deckers]
application/vnd.kahootz 'IANA,[Macdonald]
application/vnd.kde.karbon @karbon 'IANA,[Faure]
application/vnd.kde.kchart @chrt 'IANA,[Faure]
application/vnd.kde.kformula @kfo 'IANA,[Faure]
application/vnd.kde.kivio @flw 'IANA,[Faure]
application/vnd.kde.kontour @kon 'IANA,[Faure]
application/vnd.kde.kpresenter @kpr,kpt 'IANA,[Faure]
application/vnd.kde.kspread @ksp 'IANA,[Faure]
application/vnd.kde.kword @kwd,kwt 'IANA,[Faure]
application/vnd.kenameaapp @htke 'IANA,[DiGiorgio-Haag]
application/vnd.kidspiration @kia 'IANA,[Bennett]
application/vnd.koan 'IANA,[Cole]
application/vnd.liberty-request+xml 'IANA,[McDowell]
application/vnd.llamagraphics.life-balance.desktop @lbd 'IANA,[White]
application/vnd.llamagraphics.life-balance.exchange+xml @lbe 'IANA,[White]
application/vnd.lotus-1-2-3 @wks,123 'IANA,[Wattenberger]
application/vnd.lotus-approach 'IANA,[Wattenberger]
application/vnd.lotus-freelance 'IANA,[Wattenberger]
application/vnd.lotus-notes 'IANA,[Laramie]
application/vnd.lotus-organizer 'IANA,[Wattenberger]
application/vnd.lotus-screencam 'IANA,[Wattenberger]
application/vnd.lotus-wordpro 'IANA,[Wattenberger]
application/vnd.marlin.drm.mdcf 'IANA,[Ellison]
application/vnd.mcd @mcd 'IANA,[Gotoh]
application/vnd.mediastation.cdkey 'IANA,[Flurry]
application/vnd.meridian-slingshot 'IANA,[Wedel]
application/vnd.mfmp @mfm 'IANA,[Ikeda]
application/vnd.micrografx.flo @flo 'IANA,[Prevo]
application/vnd.micrografx.igx @igx 'IANA,[Prevo]
application/vnd.mif @mif 'IANA,[Wexler]
application/vnd.minisoft-hp3000-save 'IANA,[Bartram]
application/vnd.mitsubishi.misty-guard.trustweb 'IANA,[Tanaka]
application/vnd.mophun.application @mpn 'IANA,[Wennerstrom]
application/vnd.mophun.certificate @mpc 'IANA,[Wennerstrom]
application/vnd.motorola.flexsuite 'IANA,[Patton]
application/vnd.motorola.flexsuite.adsi 'IANA,[Patton]
application/vnd.motorola.flexsuite.fis 'IANA,[Patton]
application/vnd.motorola.flexsuite.gotap 'IANA,[Patton]
application/vnd.motorola.flexsuite.kmr 'IANA,[Patton]
application/vnd.motorola.flexsuite.ttc 'IANA,[Patton]
application/vnd.motorola.flexsuite.wem 'IANA,[Patton]
application/vnd.mozilla.xul+xml @xul 'IANA,[McDaniel]
application/vnd.ms-artgalry @cil 'IANA,[Slawson]
application/vnd.ms-asf @asf 'IANA,[Fleischman]
application/vnd.ms-cab-compressed @cab 'IANA,[Scarborough]
application/vnd.ms-excel @xls,xlt :base64 'IANA,[Gill]
application/vnd.ms-fontobject 'IANA,[Scarborough]
application/vnd.ms-ims 'IANA,[Ledoux]
application/vnd.ms-lrm @lrm 'IANA,[Ledoux]
application/vnd.ms-powerpoint @ppt,pps,pot :base64 'IANA,[Gill]
application/vnd.ms-project @mpp :base64 'IANA,[Gill]
application/vnd.ms-tnef :base64 'IANA,[Gill]
application/vnd.ms-works :base64 'IANA,[Gill]
application/vnd.ms-wpl @wpl :base64 'IANA,[Plastina]
application/vnd.mseq @mseq 'IANA,[Le Bodic]
application/vnd.msign 'IANA,[Borcherding]
application/vnd.music-niff 'IANA,[Butler]
application/vnd.musician 'IANA,[Adams]
application/vnd.nervana @ent,entity,req,request,bkm,kcm 'IANA,[Judkins]
application/vnd.netfpx 'IANA,[Mutz]
application/vnd.noblenet-directory 'IANA,[Solomon]
application/vnd.noblenet-sealer 'IANA,[Solomon]
application/vnd.noblenet-web 'IANA,[Solomon]
application/vnd.nokia.landmark+wbxml 'IANA,[Nokia]
application/vnd.nokia.landmark+xml 'IANA,[Nokia]
application/vnd.nokia.landmarkcollection+xml 'IANA,[Nokia]
application/vnd.nokia.radio-preset @rpst 'IANA,[Nokia]
application/vnd.nokia.radio-presets @rpss 'IANA,[Nokia]
application/vnd.novadigm.EDM 'IANA,[Swenson]
application/vnd.novadigm.EDX 'IANA,[Swenson]
application/vnd.novadigm.EXT 'IANA,[Swenson]
application/vnd.obn 'IANA,[Hessling]
application/vnd.omads-email+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.omads-file+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.omads-folder+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.osa.netdeploy 'IANA,[Klos]
application/vnd.osgi.dp 'IANA,[Kriens]
application/vnd.palm @prc,pdb,pqa,oprc :base64 'IANA,[Peacock]
application/vnd.paos.xml 'IANA,[Kemp]
application/vnd.pg.format 'IANA,[Gandert]
application/vnd.pg.osasli 'IANA,[Gandert]
application/vnd.piaccess.application-licence 'IANA,[Maneos]
application/vnd.picsel @efif 'IANA,[Naccarato]
application/vnd.powerbuilder6 'IANA,[Guy]
application/vnd.powerbuilder6-s 'IANA,[Guy]
application/vnd.powerbuilder7 'IANA,[Shilts]
application/vnd.powerbuilder7-s 'IANA,[Shilts]
application/vnd.powerbuilder75 'IANA,[Shilts]
application/vnd.powerbuilder75-s 'IANA,[Shilts]
application/vnd.preminet 'IANA,[Tenhunen]
application/vnd.previewsystems.box 'IANA,[Smolgovsky]
application/vnd.proteus.magazine 'IANA,[Hoch]
application/vnd.publishare-delta-tree 'IANA,[Ben-Kiki]
application/vnd.pvi.ptid1 @pti,ptid 'IANA,[Lamb]
application/vnd.pwg-multiplexed 'RFC3391
application/vnd.pwg-xhtml-print+xml 'IANA,[Wright]
application/vnd.rapid 'IANA,[Szekely]
application/vnd.ruckus.download 'IANA,[Harris]
application/vnd.s3sms 'IANA,[Tarkkala]
application/vnd.sealed.doc @sdoc,sdo,s1w 'IANA,[Petersen]
application/vnd.sealed.eml @seml,sem 'IANA,[Petersen]
application/vnd.sealed.mht @smht,smh 'IANA,[Petersen]
application/vnd.sealed.net 'IANA,[Lambert]
application/vnd.sealed.ppt @sppt,spp,s1p 'IANA,[Petersen]
application/vnd.sealed.xls @sxls,sxl,s1e 'IANA,[Petersen]
application/vnd.sealedmedia.softseal.html @stml,stm,s1h 'IANA,[Petersen]
application/vnd.sealedmedia.softseal.pdf @spdf,spd,s1a 'IANA,[Petersen]
application/vnd.seemail @see 'IANA,[Webb]
application/vnd.sema 'IANA,[Hansson]
application/vnd.shana.informed.formdata 'IANA,[Selzler]
application/vnd.shana.informed.formtemplate 'IANA,[Selzler]
application/vnd.shana.informed.interchange 'IANA,[Selzler]
application/vnd.shana.informed.package 'IANA,[Selzler]
application/vnd.smaf @mmf 'IANA,[Takahashi]
application/vnd.sss-cod 'IANA,[Dani]
application/vnd.sss-dtf 'IANA,[Bruno]
application/vnd.sss-ntf 'IANA,[Bruno]
application/vnd.street-stream 'IANA,[Levitt]
application/vnd.sus-calendar @sus,susp 'IANA,[Niedfeldt]
application/vnd.svd 'IANA,[Becker]
application/vnd.swiftview-ics 'IANA,[Widener]
application/vnd.syncml.+xml 'IANA,[OMA Data Synchronization Working Group]
application/vnd.syncml.ds.notification 'IANA,[OMA Data Synchronization Working Group]
application/vnd.triscape.mxs 'IANA,[Simonoff]
application/vnd.trueapp 'IANA,[Hepler]
application/vnd.truedoc 'IANA,[Chase]
application/vnd.ufdl 'IANA,[Manning]
application/vnd.uiq.theme 'IANA,[Ocock]
application/vnd.uplanet.alert 'IANA,[Martin]
application/vnd.uplanet.alert-wbxml 'IANA,[Martin]
application/vnd.uplanet.bearer-choice 'IANA,[Martin]
application/vnd.uplanet.bearer-choice-wbxml 'IANA,[Martin]
application/vnd.uplanet.cacheop 'IANA,[Martin]
application/vnd.uplanet.cacheop-wbxml 'IANA,[Martin]
application/vnd.uplanet.channel 'IANA,[Martin]
application/vnd.uplanet.channel-wbxml 'IANA,[Martin]
application/vnd.uplanet.list 'IANA,[Martin]
application/vnd.uplanet.list-wbxml 'IANA,[Martin]
application/vnd.uplanet.listcmd 'IANA,[Martin]
application/vnd.uplanet.listcmd-wbxml 'IANA,[Martin]
application/vnd.uplanet.signal 'IANA,[Martin]
application/vnd.vcx 'IANA,[T.Sugimoto]
application/vnd.vectorworks 'IANA,[Pharr]
application/vnd.vidsoft.vidconference @vsc :8bit 'IANA,[Hess]
application/vnd.visio @vsd,vst,vsw,vss 'IANA,[Sandal]
application/vnd.visionary @vis 'IANA,[Aravindakumar]
application/vnd.vividence.scriptfile 'IANA,[Risher]
application/vnd.vsf 'IANA,[Rowe]
application/vnd.wap.sic @sic 'IANA,[WAP-Forum]
application/vnd.wap.slc @slc 'IANA,[WAP-Forum]
application/vnd.wap.wbxml @wbxml 'IANA,[Stark]
application/vnd.wap.wmlc @wmlc 'IANA,[Stark]
application/vnd.wap.wmlscriptc @wmlsc 'IANA,[Stark]
application/vnd.webturbo @wtb 'IANA,[Rehem]
application/vnd.wordperfect @wpd 'IANA,[Scarborough]
application/vnd.wqd @wqd 'IANA,[Bostrom]
application/vnd.wrq-hp3000-labelled 'IANA,[Bartram]
application/vnd.wt.stf 'IANA,[Wohler]
application/vnd.wv.csp+wbxml @wv 'IANA,[Salmi]
application/vnd.wv.csp+xml :8bit 'IANA,[Ingimundarson]
application/vnd.wv.ssp+xml :8bit 'IANA,[Ingimundarson]
application/vnd.xara 'IANA,[Matthewman]
application/vnd.xfdl 'IANA,[Manning]
application/vnd.yamaha.hv-dic @hvd 'IANA,[Yamamoto]
application/vnd.yamaha.hv-script @hvs 'IANA,[Yamamoto]
application/vnd.yamaha.hv-voice @hvp 'IANA,[Yamamoto]
application/vnd.yamaha.smaf-audio @saf 'IANA,[Shinoda]
application/vnd.yamaha.smaf-phrase @spf 'IANA,[Shinoda]
application/vnd.yellowriver-custom-menu 'IANA,[Yellow]
application/vnd.zzazz.deck+xml 'IANA,[Hewett]
application/voicexml+xml 'DRAFT:draft-froumentin-voice-mediatypes
application/watcherinfo+xml @wif 'RFC3858
application/whoispp-query 'RFC2957
application/whoispp-response 'RFC2958
application/wita 'IANA,[Campbell]
application/wordperfect5.1 @wp5,wp 'IANA,[Lindner]
application/x400-bp 'RFC1494
application/xcap-att+xml 'DRAFT:draft-ietf-simple-xcap
application/xcap-caps+xml 'DRAFT:draft-ietf-simple-xcap
application/xcap-el+xml 'DRAFT:draft-ietf-simple-xcap
application/xcap-error+xml 'DRAFT:draft-ietf-simple-xcap
application/xhtml+xml @xhtml :8bit 'RFC3236
application/xml @xml :8bit 'RFC3023
application/xml-dtd :8bit 'RFC3023
application/xml-external-parsed-entity 'RFC3023
application/xmpp+xml 'RFC3923
application/xop+xml 'IANA,[Nottingham]
application/xv+xml 'DRAFT:draft-mccobb-xv-media-type
application/zip @zip :base64 'IANA,[Lindner]

  # Registered: audio/*
!audio/vnd.qcelp 'IANA,RFC3625 =use-instead:audio/QCELP
audio/32kadpcm 'RFC2421,RFC2422
audio/3gpp @3gpp 'RFC3839,DRAFT:draft-gellens-bucket
audio/3gpp2 'DRAFT:draft-garudadri-avt-3gpp2-mime
audio/AMR @amr :base64 'RFC3267
audio/AMR-WB @awb :base64 'RFC3267
audio/BV16 'RFC4298
audio/BV32 'RFC4298
audio/CN 'RFC3389
audio/DAT12 'RFC3190
audio/DVI4 'RFC3555
audio/EVRC @evc 'RFC3558
audio/EVRC-QCP 'RFC3625
audio/EVRC0 'RFC3558
audio/G722 'RFC3555
audio/G7221 'RFC3047
audio/G723 'RFC3555
audio/G726-16 'RFC3555
audio/G726-24 'RFC3555
audio/G726-32 'RFC3555
audio/G726-40 'RFC3555
audio/G728 'RFC3555
audio/G729 'RFC3555
audio/G729D 'RFC3555
audio/G729E 'RFC3555
audio/GSM 'RFC3555
audio/GSM-EFR 'RFC3555
audio/L16 @l16 'RFC3555
audio/L20 'RFC3190
audio/L24 'RFC3190
audio/L8 'RFC3555
audio/LPC 'RFC3555
audio/MP4A-LATM 'RFC3016
audio/MPA 'RFC3555
audio/PCMA 'RFC3555
audio/PCMU 'RFC3555
audio/QCELP @qcp 'RFC3555'RFC3625
audio/RED 'RFC3555
audio/SMV @smv 'RFC3558
audio/SMV-QCP 'RFC3625
audio/SMV0 'RFC3558
audio/VDVI 'RFC3555
audio/VMR-WB 'DRAFT:draft-ietf-avt-rtp-vmr-wb,DRAFT:draft-ietf-avt-rtp-vmr-wb-extension
audio/ac3 'RFC4184
audio/amr-wb+ 'DRAFT:draft-ietf-avt-rtp-amrwbplus
audio/basic @au,snd :base64 'RFC2045,RFC2046
audio/clearmode 'RFC4040
audio/dsr-es201108 'RFC3557
audio/dsr-es202050 'RFC4060
audio/dsr-es202211 'RFC4060
audio/dsr-es202212 'RFC4060
audio/iLBC 'RFC3952
audio/mp4 'DRAFT:draft-lim-mpeg4-mime
audio/mpa-robust 'RFC3119
audio/mpeg @mpga,mp2,mp3 :base64 'RFC3003
audio/mpeg4-generic 'RFC3640
audio/parityfec 'RFC3009
audio/prs.sid @sid,psid 'IANA,[Walleij]
audio/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission
audio/t140c 'DRAFT:draft-ietf-avt-audio-t140c
audio/telephone-event 'RFC2833
audio/tone 'RFC2833
audio/vnd.3gpp.iufp 'IANA,[Belling]
audio/vnd.audiokoz 'IANA,[DeBarros]
audio/vnd.cisco.nse 'IANA,[Kumar]
audio/vnd.cmles.radio-events 'IANA,[Goulet]
audio/vnd.cns.anp1 'IANA,[McLaughlin]
audio/vnd.cns.inf1 'IANA,[McLaughlin]
audio/vnd.digital-winds @eol :7bit 'IANA,[Strazds]
audio/vnd.dlna.adts 'IANA,[Heredia]
audio/vnd.everad.plj @plj 'IANA,[Cicelsky]
audio/vnd.lucent.voice @lvp 'IANA,[Vaudreuil]
audio/vnd.nokia.mobile-xmf @mxmf 'IANA,[Nokia Corporation]
audio/vnd.nortel.vbk @vbk 'IANA,[Parsons]
audio/vnd.nuera.ecelp4800 @ecelp4800 'IANA,[Fox]
audio/vnd.nuera.ecelp7470 @ecelp7470 'IANA,[Fox]
audio/vnd.nuera.ecelp9600 @ecelp9600 'IANA,[Fox]
audio/vnd.octel.sbc 'IANA,[Vaudreuil]
audio/vnd.rhetorex.32kadpcm 'IANA,[Vaudreuil]
audio/vnd.sealedmedia.softseal.mpeg @smp3,smp,s1m 'IANA,[Petersen]
audio/vnd.vmx.cvsd 'IANA,[Vaudreuil]

  # Registered: image/*
image/cgm 'IANA =Computer Graphics Metafile [Francis]
image/fits 'RFC4047
image/g3fax 'RFC1494
image/gif @gif :base64 'RFC2045,RFC2046
image/ief @ief :base64 'RFC1314 =Image Exchange Format
image/jp2 @jp2 :base64 'IANA,RFC3745
image/jpeg @jpeg,jpg,jpe :base64 'RFC2045,RFC2046
image/jpm @jpm :base64 'IANA,RFC3745
image/jpx @jpx :base64 'IANA,RFC3745
image/naplps 'IANA,[Ferber]
image/png @png :base64 'IANA,[Randers-Pehrson]
image/prs.btif 'IANA,[Simon]
image/prs.pti 'IANA,[Laun]
image/t38 'RFC3362
image/tiff @tiff,tif :base64 'RFC3302 =Tag Image File Format
image/tiff-fx 'RFC3950 =Tag Image File Format Fax eXtended
image/vnd.adobe.photoshop 'IANA,[Scarborough]
image/vnd.cns.inf2 'IANA,[McLaughlin]
image/vnd.djvu @djvu,djv 'IANA,[Bottou]
image/vnd.dwg @dwg 'IANA,[Moline]
image/vnd.dxf 'IANA,[Moline]
image/vnd.fastbidsheet 'IANA,[Becker]
image/vnd.fpx 'IANA,[Spencer]
image/vnd.fst 'IANA,[Fuldseth]
image/vnd.fujixerox.edmics-mmr 'IANA,[Onda]
image/vnd.fujixerox.edmics-rlc 'IANA,[Onda]
image/vnd.globalgraphics.pgb @pgb 'IANA,[Bailey]
image/vnd.microsoft.icon @ico 'IANA,[Butcher]
image/vnd.mix 'IANA,[Reddy]
image/vnd.ms-modi @mdi 'IANA,[Vaughan]
image/vnd.net-fpx 'IANA,[Spencer]
image/vnd.sealed.png @spng,spn,s1n 'IANA,[Petersen]
image/vnd.sealedmedia.softseal.gif @sgif,sgi,s1g 'IANA,[Petersen]
image/vnd.sealedmedia.softseal.jpg @sjpg,sjp,s1j 'IANA,[Petersen]
image/vnd.svf 'IANA,[Moline]
image/vnd.wap.wbmp @wbmp 'IANA,[Stark]
image/vnd.xiff 'IANA,[S.Martin]

  # Registered: message/*
message/CPIM 'RFC3862
message/delivery-status 'RFC1894
message/disposition-notification 'RFC2298
message/external-body :8bit 'RFC2046
message/http 'RFC2616
message/news :8bit 'RFC1036,[H.Spencer]
message/partial :8bit 'RFC2046
message/rfc822 :8bit 'RFC2046
message/s-http 'RFC2660
message/sip 'RFC3261
message/sipfrag 'RFC3420
message/tracking-status 'RFC3886

  # Registered: model/*
model/iges @igs,iges 'IANA,[Parks]
model/mesh @msh,mesh,silo 'RFC2077
model/vnd.dwf 'IANA,[Pratt]
model/vnd.flatland.3dml 'IANA,[Powers]
model/vnd.gdl 'IANA,[Babits]
model/vnd.gs-gdl 'IANA,[Babits]
model/vnd.gtw 'IANA,[Ozaki]
model/vnd.mts 'IANA,[Rabinovitch]
model/vnd.parasolid.transmit.binary @x_b,xmt_bin 'IANA,[Parasolid]
model/vnd.parasolid.transmit.text @x_t,xmt_txt :quoted-printable 'IANA,[Parasolid]
model/vnd.vtu 'IANA,[Rabinovitch]
model/vrml @wrl,vrml 'RFC2077

  # Registered: multipart/*
multipart/alternative :8bit 'RFC2045,RFC2046
multipart/appledouble :8bit 'IANA,[Faltstrom]
multipart/byteranges 'RFC2068
multipart/digest :8bit 'RFC2045,RFC2046
multipart/encrypted 'RFC1847
multipart/form-data 'RFC2388
multipart/header-set 'IANA,[Crocker]
multipart/mixed :8bit 'RFC2045,RFC2046
multipart/parallel :8bit 'RFC2045,RFC2046
multipart/related 'RFC2387
multipart/report 'RFC1892
multipart/signed 'RFC1847
multipart/voice-message 'RFC2421,RFC2423

  # Registered: text/*
!text/ecmascript 'DRAFT:draft-hoehrmann-script-types
!text/javascript 'DRAFT:draft-hoehrmann-script-types
text/calendar 'RFC2445
text/css @css :8bit 'RFC2318
text/csv @csv :8bit 'RFC4180
text/directory 'RFC2425
text/dns 'RFC4027
text/enriched 'RFC1896
text/html @html,htm,htmlx,shtml,htx :8bit 'RFC2854
text/parityfec 'RFC3009
text/plain @txt,asc,c,cc,h,hh,cpp,hpp,dat,hlp 'RFC2046,RFC3676
text/prs.fallenstein.rst @rst 'IANA,[Fallenstein]
text/prs.lines.tag 'IANA,[Lines]
text/RED 'RFC4102
text/rfc822-headers 'RFC1892
text/richtext @rtx :8bit 'RFC2045,RFC2046
text/rtf @rtf :8bit 'IANA,[Lindner]
text/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission
text/sgml @sgml,sgm 'RFC1874
text/t140 'RFC4103
text/tab-separated-values @tsv 'IANA,[Lindner]
text/troff @t,tr,roff,troff :8bit 'DRAFT:draft-lilly-text-troff
text/uri-list 'RFC2483
text/vnd.abc 'IANA,[Allen]
text/vnd.curl 'IANA,[Byrnes]
text/vnd.DMClientScript 'IANA,[Bradley]
text/vnd.esmertec.theme-descriptor 'IANA,[Eilemann]
text/vnd.fly 'IANA,[Gurney]
text/vnd.fmi.flexstor 'IANA,[Hurtta]
text/vnd.in3d.3dml 'IANA,[Powers]
text/vnd.in3d.spot 'IANA,[Powers]
text/vnd.IPTC.NewsML '[IPTC]
text/vnd.IPTC.NITF '[IPTC]
text/vnd.latex-z 'IANA,[Lubos]
text/vnd.motorola.reflex 'IANA,[Patton]
text/vnd.ms-mediapackage 'IANA,[Nelson]
text/vnd.net2phone.commcenter.command @ccc 'IANA,[Xie]
text/vnd.sun.j2me.app-descriptor @jad :8bit 'IANA,[G.Adams]
text/vnd.wap.si @si 'IANA,[WAP-Forum]
text/vnd.wap.sl @sl 'IANA,[WAP-Forum]
text/vnd.wap.wml @wml 'IANA,[Stark]
text/vnd.wap.wmlscript @wmls 'IANA,[Stark]
text/xml @xml,dtd :8bit 'RFC3023
text/xml-external-parsed-entity 'RFC3023
vms:text/plain @doc :8bit

  # Registered: video/*
video/3gpp @3gp,3gpp 'RFC3839,DRAFT:draft-gellens-mime-bucket 
video/3gpp-tt 'DRAFT:draft-ietf-avt-rtp-3gpp-timed-text 
video/3gpp2 'DRAFT:draft-garudadri-avt-3gpp2-mime 
video/BMPEG 'RFC3555 
video/BT656 'RFC3555 
video/CelB 'RFC3555 
video/DV 'RFC3189 
video/H261 'RFC3555 
video/H263 'RFC3555 
video/H263-1998 'RFC3555 
video/H263-2000 'RFC3555 
video/H264 'RFC3984 
video/JPEG 'RFC3555 
video/MJ2 @mj2,mjp2 'RFC3745 
video/MP1S 'RFC3555 
video/MP2P 'RFC3555 
video/MP2T 'RFC3555 
video/mp4 'DRAFT:draft-lim-mpeg4-mime 
video/MP4V-ES 'RFC3016 
video/mpeg @mp2,mpe,mp3g,mpg :base64 'RFC2045,RFC2046 
video/mpeg4-generic 'RFC3640 
video/MPV 'RFC3555 
video/nv 'RFC3555 
video/parityfec 'RFC3009 
video/pointer 'RFC2862 
video/quicktime @qt,mov :base64 'IANA,[Lindner] 
video/raw 'RFC4175 
video/rtx 'DRAFT:draft-ietf-avt-rtp-retransmission 
video/SMPTE292M 'RFC3497 
video/vnd.dlna.mpeg-tts 'IANA,[Heredia] 
video/vnd.fvt 'IANA,[Fuldseth] 
video/vnd.motorola.video 'IANA,[McGinty] 
video/vnd.motorola.videop 'IANA,[McGinty] 
video/vnd.mpegurl @mxu,m4u :8bit 'IANA,[Recktenwald] 
video/vnd.nokia.interleaved-multimedia @nim 'IANA,[Kangaslampi] 
video/vnd.objectvideo @mp4 'IANA,[Clark] 
video/vnd.sealed.mpeg1 @s11 'IANA,[Petersen] 
video/vnd.sealed.mpeg4 @smpg,s14 'IANA,[Petersen] 
video/vnd.sealed.swf @sswf,ssw 'IANA,[Petersen] 
video/vnd.sealedmedia.softseal.mov @smov,smo,s1q 'IANA,[Petersen] 
video/vnd.vivo @viv,vivo 'IANA,[Wolfe] 

  # Unregistered: application/*
!application/x-troff 'LTSW =use-instead:text/troff
application/x-bcpio @bcpio 'LTSW
application/x-compressed @z,Z :base64 'LTSW
application/x-cpio @cpio :base64 'LTSW
application/x-csh @csh :8bit 'LTSW
application/x-dvi @dvi :base64 'LTSW
application/x-gtar @gtar,tgz,tbz2,tbz :base64 'LTSW
application/x-gzip @gz :base64 'LTSW
application/x-hdf @hdf 'LTSW
application/x-java-archive @jar 'LTSW
application/x-java-jnlp-file @jnlp 'LTSW
application/x-java-serialized-object @ser 'LTSW
application/x-java-vm @class 'LTSW
application/x-latex @ltx,latex :8bit 'LTSW
application/x-mif @mif 'LTSW
application/x-rtf 'LTSW =use-instead:application/rtf
application/x-sh @sh 'LTSW
application/x-shar @shar 'LTSW
application/x-stuffit @sit :base64 'LTSW
application/x-sv4cpio @sv4cpio :base64 'LTSW
application/x-sv4crc @sv4crc :base64 'LTSW
application/x-tar @tar :base64 'LTSW
application/x-tcl @tcl :8bit 'LTSW
application/x-tex @tex :8bit
application/x-texinfo @texinfo,texi :8bit
application/x-troff-man @man :8bit 'LTSW
application/x-troff-me @me 'LTSW
application/x-troff-ms @ms 'LTSW
application/x-ustar @ustar :base64 'LTSW
application/x-wais-source @src 'LTSW
mac:application/x-mac @bin :base64
*!application/cals1840 'LTSW =use-instead:application/cals-1840
*!application/remote_printing 'LTSW =use-instead:application/remote-printing
*!application/x-u-star 'LTSW =use-instead:application/x-ustar
*!application/x400.bp 'LTSW =use-instead:application/x400-bp
*application/acad 'LTSW
*application/clariscad 'LTSW
*application/drafting 'LTSW
*application/dxf 'LTSW
*application/excel @xls,xlt 'LTSW
*application/fractals 'LTSW
*application/i-deas 'LTSW
*application/macbinary 'LTSW
*application/netcdf @nc,cdf 'LTSW
*application/powerpoint @ppt,pps,pot :base64 'LTSW
*application/pro_eng 'LTSW
*application/set 'LTSW
*application/SLA 'LTSW
*application/solids 'LTSW
*application/STEP 'LTSW
*application/vda 'LTSW
*application/word @doc,dot 'LTSW

  # Unregistered: audio/*
audio/x-aiff @aif,aifc,aiff :base64
audio/x-midi @mid,midi,kar :base64
audio/x-pn-realaudio @rm,ram :base64
audio/x-pn-realaudio-plugin @rpm
audio/x-realaudio @ra :base64
audio/x-wav @wav :base64

  # Unregistered: image/*
*image/vnd.dgn @dgn =use-instead:image/x-vnd.dgn
image/x-bmp @bmp
image/x-cmu-raster @ras
image/x-paintshoppro @psp,pspimage :base64
image/x-pict
image/x-portable-anymap @pnm :base64
image/x-portable-bitmap @pbm :base64
image/x-portable-graymap @pgm :base64
image/x-portable-pixmap @ppm :base64
image/x-rgb @rgb :base64
image/x-targa @tga
image/x-vnd.dgn @dgn
image/x-win-bmp
image/x-xbitmap @xbm :7bit
image/x-xbm @xbm :7bit
image/x-xpixmap @xpm :8bit
image/x-xwindowdump @xwd :base64
*!image/cmu-raster =use-instead:image/x-cmu-raster
*!image/vnd.net.fpx =use-instead:image/vnd.net-fpx
*image/bmp @bmp
*image/targa @tga

  # Unregistered: multipart/*
multipart/x-gzip
multipart/x-mixed-replace
multipart/x-tar
multipart/x-ustar
multipart/x-www-form-urlencoded
multipart/x-zip
*!multipart/parallel =use-instead:multipart/parallel

  # Unregistered: text/*
*text/comma-separated-values @csv :8bit
*text/vnd.flatland.3dml =use-instead:model/vnd.flatland.3dml
text/x-vnd.flatland.3dml =use-instead:model/vnd.flatland.3dml
text/x-setext @etx
text/x-vcalendar @vcs :8bit
text/x-vcard @vcf :8bit
text/x-yaml @yaml,yml :8bit

  # Unregistered: video/*
*video/dl @dl :base64
*video/gl @gl :base64
video/x-msvideo @avi :base64
video/x-sgi-movie @movie :base64

  # Unregistered: other/*
x-chemical/x-pdb @pdb
x-chemical/x-xyz @xyz
x-conference/x-cooltalk @ice
x-drawing/dwf @dwf
x-world/x-vrml @wrl,vrml
MIME_TYPES

_re = %r{
  ^
  ([*])?                                # 0: Unregistered?
  (!)?                                  # 1: Obsolete?
  (?:(\w+):)?                           # 2: Platform marker
  #{MIME::Type::MEDIA_TYPE_RE}          # 3,4: Media type
  (?:\s@([^\s]+))?                      # 5: Extensions
  (?:\s:(#{MIME::Type::ENCODING_RE}))?  # 6: Encoding
  (?:\s'(.+))?                          # 7: URL list
  (?:\s=(.+))?                          # 8: Documentation
  $
}x

data_mime_type.each_line do |i|
  item = i.chomp.strip.gsub(%r{#.*}o, '')
  next if item.empty?

  m = _re.match(item).captures

  unregistered, obsolete, platform, mediatype, subtype, extensions,
    encoding, urls, docs = *m

  extensions &&= extensions.split(/,/)
  urls &&= urls.split(/,/)

  mime_type = MIME::Type.new("#{mediatype}/#{subtype}") do |t|
    t.extensions  = extensions
    t.encoding    = encoding
    t.system      = platform
    t.obsolete    = obsolete
    t.registered  = false if unregistered
    t.docs        = docs
    t.url         = urls
  end

  MIME::Types.add_type_variant(mime_type)
  MIME::Types.index_extensions(mime_type)
end

_re             = nil
data_mime_type  = nil
