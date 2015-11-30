# @test Hello World

require 'metaheader/version'

class MetaHeader
  REQUIRED = true
  OPTIONAL = nil

  REGEX = /\A(?<prefix>.*?)
    (?:@(?<key>\w+)|(?<key>[^:]+)\s*:)
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
    @data = {}

    last_key = nil
    last_prefix = String.new

    input.each_line {|line|
      break if line.strip.empty?

      unless match = REGEX.match(line)
        # multiline value must have the same prefix
        next unless line.index(last_prefix) == 0

        # remove the line prefix
        line = line[last_prefix.size..-1]
        stripped = line.strip

        if last_key && line.index(stripped) > 0
          if @data[last_key].is_a? String
            @data[last_key] += "\n"
          else
            @data[last_key] = String.new
          end

          @data[last_key] += stripped
        end

        next
      end

      last_prefix = match[:prefix]
      last_key = match[:key].to_sym

      @data[last_key] = match[:value] || true
    }
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

  def validate(rules)
    errors = Hash.new

    @data.each_key {|key|
      unless rules.has_key? key
        errors[:unknown] ||= Array.new
        errors[:unknown] << key
      end
    }

    rules.each_pair {|key, rule|
      if key_errors = validate_key(key, rule)
        errors.merge! key_errors
      end
    }

    errors.empty? ? nil : errors
  end

  def validate_key(key, rule)
    return unless rule

    errors = Hash.new

    case rule
    when true
      if !@data.has_key? key
        errors[:missing] ||= Array.new
        errors[:missing] << key
      end
    when Regexp
      if !rule.match(@data[key])
        errors[:invalid] ||= Array.new
        errors[:invalid] << key
      end
    else
      raise ArgumentError
    end

    errors.empty? ? nil : errors
  end
end
