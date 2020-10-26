require 'metaheader/version'

require 'stringio'

# Parser for metadata header in plain-text files
# @example
#   mh = MetaHeader.parse '@hello world'
#   puts mh[:hello]
class MetaHeader
  # Allow a tag to be omitted when validating in strict mode.
  OPTIONAL = Object.new.freeze

  # Ensure a tag exists during validation.
  REQUIRED = Object.new.freeze

  # The tag cannot hold a value beside true or false during validation.
  BOOLEAN = Object.new.freeze

  # The tag must have a string value (non-boolean tag) during validation.
  VALUE = Object.new.freeze

  # Don't allow multiline values during validation.
  SINGLELINE = Object.new.freeze

  # Create a new instance from the contents of a file.
  # @param path [String] path to the file to be read
  # @return [MetaHeader]
  def self.from_file(path)
    File.open(path) {|file| self.parse file }
  end

  # Construct a MetaHeader object and parse every tags found in the input up to
  # the first newline.
  # @param input [String, IO, StringIO]
  # @return [MetaHeader]
  def self.parse(input)
    mh = MetaHeader.new
    mh.parse input
    mh
  end

  # Construct a blank MetaHeader object
  def initialize
    @data = {}
  end

  # Parse every tags found in the input up to the first newline.
  # @param input [String, IO, StringIO]
  # @return [Integer] Character position of the first content line in the input
  # data following the header.
  def parse(input)
    if input.is_a? String
      input = StringIO.new input.encode universal_newline: true
    end

    @last_tag = nil
    @empty_lines = 0

    content_offset = 0
    input.each_line do |line|
      full_line_size = line.size # parse_line can trim the line
      continue = parse_line line
      content_offset += full_line_size if continue || line.empty?
      break unless continue
    end
    content_offset
  end

  # Returns the value of a tag by its name, or nil if not found.
  # @param key [Symbol] tag name
  # @param default [Object] value to return if key doesn't exist
  # @return [Object, nil]
  def [](key, default = nil)
    if tag = @data[key]
      tag.value
    else
      default
    end
  end

  # Replaces the value of a tag.
  # @param value the new value
  # @return [Object] value
  def []=(key, value)
    raise ArgumentError, 'value cannot be nil' if value.nil?

    @data[key] ||= Tag.new key
    @data[key].value = value
  end

  # Returns how many tags were found in the input.
  # @return [Integer]
  def size
    @data.size
  end

  # Whether any tags were found in the input.
  # @return [Boolean]
  def empty?
    @data.empty?
  end

  # Whether a tag was found in the input.
  # @param tag [Symbol] the tag to lookup
  # @return [Boolean]
  def has?(tag)
    @data.has_key? tag
  end

  # Removes a given tag from the list.
  # @param tag [Symbol] the tag to remove
  def delete(tag)
    @data.delete tag
  end

  # Make a hash from the parsed data
  # @return [Hash<Symbol, Object>]
  def to_h
    Hash[@data.map {|name, tag| [name, tag.value] }]
  end

  # Makes a human-readable representation of the current instance.
  # @return [String]
  def inspect
    "#<#{self.class} #{to_h}>"
  end

  # Validates parsed data according to a custom set of rules.
  # A rule can be one of the predefined constants, a regex, a proc or a
  # method (returing nil if the tag is valid or an error string otherwise).
  # @example
  #   mh = MetaHeader.new "@hello world\n@chunky bacon"
  #   mh.validate \
  #     hello: [MetaHeader::REQUIRED, MetaHeader::SINGLELINE, /\d/],
  #     chunky: proc {|value| 'not bacon' unless value == 'bacon' }
  # @param rules [Hash] :tag_name => rule or [rule1, rule2, ...]
  # @param strict [Boolean] Whether to report unknown tags as errors
  # @return [Array<String>] List of error messasges
  # @see OPTIONAL
  # @see REQUIRED
  # @see BOOLEAN
  # @see VALUE
  # @see SINGLELINE
  def validate(rules, strict = false)
    errors = []

    if strict
      @data.each {|key, tag|
        errors << "unknown tag '%s'" % tag.name unless rules.has_key? key
      }
    end

    rules.each_pair {|key, rule|
      if key_error = validate_key(key, rule)
        errors << key_error
      end
    }

    errors
  end

  # Rename one or more tags.
  # @param old [Symbol, Array<Symbol>, Hash<Symbol, Symbol>]
  # @param new [Symbol] Ignored if old is a Hash
  # @example
  #   mh.alias :old, :new
  #   mh.alias [:old1, :old2], :new
  #   mh.alias old1: :new1, old2: :new2
  def alias(old, new = nil)
    if old.is_a? Hash
      old.each {|k, v| self.alias k, v }
    else
      Array(old).each {|tag|
        @data[new] = delete tag if has? tag
      }
    end
  end

private
  # @api private
  Tag = Struct.new :name, :value

  REGEX = /\A(?<prefix>.*?)
    (?:@(?<key>\w+)|(?<key>[\w][\w\s]*?)\s*(?<alt>:))
    (?:\s*(?<value>[^\n]+))?
    \Z/x.freeze

  def parse_line(line)
    line.chomp!
    line.encode! Encoding::UTF_8, invalid: :replace

    # multiline value must have the same line prefix as the key
    if @last_tag && line.start_with?(@last_prefix.rstrip)
      if append line
        return true
      else
        @last_tag = nil
      end
    end

    line.rstrip!

    return false if @empty_lines > 0
    return !line.empty? unless match = REGEX.match(line)

    # single line
    @last_prefix = match[:prefix]

    @raw_value = match[:value]
    value = parse_value @raw_value

    @last_tag = Tag.new match[:key].freeze, value
    @line_breaks = 0
    @block_indent = nil

    # disable implicit values with the alternate syntax
    register @last_tag unless match[:alt] && match[:value].nil?

    # ok, give me another line!
    true
  end

  def register(tag)
    return if has? tag
    key = tag.name.downcase.gsub(/[^\w]/, '_').to_sym
    @data[key] = tag
  end

  # handle multiline tags
  def append(line)
    prefix = line.rstrip
    if prefix == @last_prefix.rstrip
      @line_breaks += 1
      @empty_lines += 1 if prefix.empty?
      return true # add the line break later
    elsif line.start_with? @last_prefix
      mline = line[@last_prefix.size..-1]

      if @block_indent
        if mline.start_with? @block_indent
          stripped = mline[@block_indent.size..-1]
        else
          return
        end
      else
        stripped = mline.lstrip
        indent_level = mline.index stripped
        return if indent_level < 1
        @block_indent = mline[0, indent_level]
      end
    else
      return
    end

    # add the tag if it uses the alternate syntax and has no value
    register @last_tag

    @last_tag.value = @raw_value.to_s unless @last_tag.value.is_a? String

    @line_breaks += 1 unless @last_tag.value.empty?
    @last_tag.value += "\n" * @line_breaks
    @line_breaks = @empty_lines = 0

    @last_tag.value += stripped
  end

  def parse_value(value)
    case value
    when 'true'
      value = true
    when 'false'
      value = false
    when nil
      value = true
    when String
      value = nil if value.empty?
    end

    value
  end

  def validate_key(key, rules)
    rules = Array(rules)
    return if rules.empty?

    unless @data.has_key? key
      if rules.include? REQUIRED
        return "missing tag '%s'" % key
      else
        return nil
      end
    end

    tag = @data[key]
    str_value = tag.value
    str_value = String.new if str_value == true

    rules.each {|rule|
      case rule
      when REQUIRED, OPTIONAL
        # nothing to do here: REQUIRED is handled in the code above
      when SINGLELINE
        if str_value.include? "\n"
          return "tag '%s' must be singleline" % tag.name
        end
      when VALUE
        if str_value.empty?
          return "missing value for tag '%s'" % tag.name
        end
      when BOOLEAN
        unless [TrueClass, FalseClass].include? tag.value.class
          return "tag '%s' cannot have a value" % tag.name
        end
      when Regexp
        unless rule.match str_value
          return "invalid value for tag '%s'" % tag.name
        end
      when Proc, Method
        if error = rule.call(tag.value)
          return "invalid value for tag '%s': %s" % [tag.name, error]
        end
      else
        raise ArgumentError, "unsupported validator #{rule}"
      end
    }

    nil
  end
end
