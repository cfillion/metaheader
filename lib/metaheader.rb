# @test Hello World

require 'metaheader/version'

class MetaHeader
  REQUIRED = Object.new.freeze
  OPTIONAL = Object.new.freeze

  attr_accessor :strict

  REGEX = /\A(?<prefix>.*?)
    (?:@(?<key>\w+)|(?<key>[\w][\w\s]*?)\s*:)
    (?:\s+(?<value>[^\n]+))?
    \Z/x.freeze

  def self.from_file(file)
    input = String.new

    File.foreach(file) {|line|
      break if line.strip.empty?
      input << line
    }

    self.new input
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
  end

  def <<(line)
    # multiline value must have the same prefix
    if @last_key && line.index(@last_prefix) == 0
      # remove the line prefix
      mline = line[@last_prefix.size..-1]
      stripped = mline.strip

      indent_level = mline.index stripped

      if indent_level > 0
        if @data[@last_key].is_a? String
          @data[@last_key] += "\n"
        else
          @data[@last_key] = String.new
        end

        @data[@last_key] += stripped

        return
      else
        @last_key = nil
      end
    end

    return unless match = REGEX.match(line)

    # single line
    @last_prefix = match[:prefix]
    @last_key = match[:key].downcase.gsub(/[^\w]/, '_').to_sym

    @data[@last_key] = match[:value] || true
  end

  def [](key)
    @data[key]
  end

  def size
    @data.size
  end

  def to_h
    @data.dup
  end

  def inspect
    @data.inspect
  end

  def validate(rules)
    errors = Array.new

    if @strict
      @data.each_key {|key|
        errors << "unknown tag #{format key}" unless rules.has_key? key
      }
    end

    rules.each_pair {|key, rule|
      if key_errors = validate_key(key, rule)
        errors.concat key_errors
      end
    }

    errors.empty? ? nil : errors
  end

  def validate_key(key, rules)
    rules = Array(rules)
    return if rules.empty?

    errors = Array.new

    unless @data.has_key? key
      if rules.include? OPTIONAL
        return nil
      else
        return ["missing tag #{format key}"]
      end
    end

    value = @data[key]
    value = String.new if value == true

    rules.each {|rule|
      case rule
      when REQUIRED, OPTIONAL
        # do nothing
      when Regexp
        unless rule.match value
          errors << "invalid value for tag #{format key}"
        end
      when Proc
        if error = rule[value]
          errors << "invalid value for tag #{format key}: #{error}"
        end
      else
        raise ArgumentError
      end
    }

    errors.empty? ? nil : errors
  end

  def format(key)
    "@#{key}"
  end
end
