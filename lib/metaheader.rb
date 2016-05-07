require 'metaheader/version'

class MetaHeader
  # @abstract Subclass and override {#parse} to implement a custom parser.
  class Parser
    class << self
      # @api private
      def inherited(k)
        @parsers ||= []
        @parsers << k
      end

      # @api private
      def each(&b)
        @parsers&.each(&b)
      end
    end

    # @return [MetaHeader] the current instance
    def header
      @mh
    end

    # @param raw_input [String]
    # @return [void]
    def parse(raw_input)
      raise NotImplementedError
    end
  end

  BOOLEAN = Object.new.freeze
  OPTIONAL = Object.new.freeze
  REQUIRED = Object.new.freeze
  SINGLELINE = Object.new.freeze
  VALUE = Object.new.freeze

  # Whether to fail validation if unknown tags are encoutered.
  # @see #validate
  # @return [Boolean]
  attr_accessor :strict

  # Create a new instance from the contents of a file.
  # @param path [String] path to the file to be read
  # @return [MetaHeader]
  def self.from_file(path)
    self.new File.read(path)
  end

  # Parse every tags found in input up to the first newline.
  # @param input [String]
  def initialize(input)
    @strict = false
    @data = {}

    @last_key = nil
    @last_prefix = String.new

    input = input.encode universal_newline: true
    input.each_line {|line|
      if line.strip.empty?
        break
      else
        parse line
      end
    }

    Parser.each {|klass|
      parser = klass.new
      parser.instance_variable_set :@mh, self
      parser.parse input
    }
  end

  # Returns the value of a tag by its name, or nil if not found.
  # @return [Object, nil]
  def [](key)
    tag = @data[key] and tag.value
  end

  # Replaces the value of a tag.
  # @param value the new value
  # @return value
  def []=(key, value)
    @data[key] ||= Tag.new key
    @data[key].value = value
  end

  # Returns how many tags were found in the input.
  # @return [Fixnum]
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
    @data.has_key? tag.to_sym
  end

  # Make a hash from the parsed data
  # @return [Hash]
  def to_h
    Hash[@data.map {|name, tag| [name, tag.value] }]
  end

  # Makes a human-readable representation of the current instance.
  # @return [String]
  def inspect
    "#<#{self.class} #{to_h}>"
  end

  # Validates parsed data according to a custom set of rules.
  # @example
  #   mh = MetaHeader.new "@hello world\n@chunky bacon"
  #   mh.validate \
  #     hello: [MetaHeader::REQUIRED, MetaHeader::SINGLELINE, /\d/],
  #     chunky: proc {|value| 'not bacon' unless value == 'bacon' }
  # @param rules [Hash] tag_name => rule or array_of_rules
  # @return [Array, nil] error list or nil
  # @see BOOLEAN
  # @see OPTIONAL
  # @see REQUIRED
  # @see SINGLELINE
  # @see VALUE
  def validate(rules)
    errors = Array.new

    if @strict
      @data.each_key {|key|
        errors << "unknown tag '%s'" % key unless rules.has_key? key
      }
    end

    rules.each_pair {|key, rule|
      if key_error = validate_key(key, rule)
        errors << key_error
      end
    }

    errors unless errors.empty?
  end

private
  # @api private
  Tag = Struct.new :name, :value

  REGEX = /\A(?<prefix>.*?)
    (?:@(?<key>\w+)|(?<key>[\w][\w\s]*?)\s*:)
    (?:\s+(?<value>[^\n]+))?
    \Z/x.freeze

  def parse(line)
    # multiline value must have the same prefix
    if @last_key && line.index(@last_prefix) == 0
      # remove the line prefix
      mline = line[@last_prefix.size..-1]
      stripped = mline.strip

      indent_level = mline.index stripped

      if indent_level > 0
        tag = @data[@last_key]

        if tag.value.is_a? String
          tag.value += "\n"
        else
          tag.value = String.new
        end

        tag.value += stripped

        return
      else
        @last_key = nil
      end
    end

    return unless match = REGEX.match(line)

    # single line
    @last_prefix = match[:prefix]
    @last_key = match[:key].downcase.gsub(/[^\w]/, '_').to_sym

    value = match[:value] || true
    @data[@last_key] = Tag.new match[:key].freeze, value
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
