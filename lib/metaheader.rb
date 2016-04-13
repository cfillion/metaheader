# @test Hello World

require 'metaheader/version'

class MetaHeader
  class Parser
    def self.each(&b)
      @parsers ||= begin
        parsers = []
        ObjectSpace.each_object(singleton_class).each {|klass|
          parsers << klass unless klass == self
        }
        parsers
      end

      @parsers.each(&b)
    end

    def initialize(mh)
      @mh = mh
    end

    def header
      @mh
    end

    def parse
      raise NotImplementedError
    end
  end

  REQUIRED = Object.new.freeze
  OPTIONAL = Object.new.freeze

  Tag = Struct.new :name, :value

  attr_accessor :strict

  REGEX = /\A(?<prefix>.*?)
    (?:@(?<key>\w+)|(?<key>[\w][\w\s]*?)\s*:)
    (?:\s+(?<value>[^\n]+))?
    \Z/x.freeze

  def self.from_file(file)
    self.new File.read(file)
  end

  def initialize(input)
    @strict = false
    @data = {}

    @last_key = nil
    @last_prefix = String.new

    input.each_line {|line|
      if line.strip.empty?
        break
      else
        self.<< line
      end
    }

    Parser.each {|klass|
      parser = klass.new self
      parser.parse input
    }
  end

  def <<(line)
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

  def [](key)
    tag = @data[key] and tag.value
  end

  def []=(key, value)
    @data[key] ||= Tag.new key
    @data[key].value = value
  end

  def size
    @data.size
  end

  def empty?
    @data.empty?
  end

  def to_h
    Hash[@data.map {|v| [v.first, v.last.value] }]
  end

  def inspect
    to_h.inspect
  end

  def validate(rules)
    errors = Array.new

    if @strict
      @data.each_key {|key|
        errors << 'unknown tag "%s"' % key unless rules.has_key? key
      }
    end

    rules.each_pair {|key, rule|
      if key_errors = validate_key(key, rule)
        errors.concat key_errors
      end
    }

    errors unless errors.empty?
  end

  def validate_key(key, rules)
    rules = Array(rules)
    return if rules.empty?

    errors = Array.new

    unless @data.has_key? key
      if rules.include? OPTIONAL
        return nil
      else
        return ['missing tag "%s"' % key]
      end
    end

    tag = @data[key]
    value = tag.value
    value = String.new if value == true

    rules.each {|rule|
      case rule
      when REQUIRED, OPTIONAL
        # do nothing
      when Regexp
        unless rule.match value
          errors << 'invalid value for tag "%s"' % tag.name
        end
      when Proc
        if error = rule[value]
          errors << 'invalid value for tag "%s": %s' % [tag.name, error]
        end
      else
        raise ArgumentError
      end
    }

    errors unless errors.empty?
  end
end
