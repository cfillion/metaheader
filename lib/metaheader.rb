# @test Hello World

require 'metaheader/version'

class MetaHeader
  REQUIRED = 1
  OPTIONAL = 2

  REGEX = /\A.*?@(?<key>\w+)(?:\s+(?<value>[^\n]+))?\Z/.freeze

  def self.from_file(file)
    self.new File.read(file)
  end

  def initialize(input)
    @data = {}

    last_key = nil
    last_index = 0

    input.each_line {|input|
      line = input.strip
      line_start = input.index line

      break if line.empty?

      unless match = REGEX.match(line)
        # multiline value
        if line_start - last_index >= 0 && last_key
          if @data[last_key].is_a? String
            @data[last_key] += "\n"
          else
            @data[last_key] = String.new
          end

          @data[last_key] += line
        end

        next
      end

      last_key = match[:key].to_sym
      last_index = line_start + match.begin(:key) - 1

      @data[last_key] = match[:value] || true
    }
  end

  def [](key)
    @data[key]
  end

  def size
    @data.size
  end

  def validate(rules)
    errors = Hash.new

    @data.each_pair {|key, value|
      unless rules.has_key? key
        errors[:unknown] ||= Array.new
        errors[:unknown] << key
      end
    }

    rules.each_pair {|key, key_rule|
      Array(key_rule).each do |rule|
        if rule == true
          if !@data.has_key? key
            errors[:missing] ||= Array.new
            errors[:missing] << key
          end
        end
      end
    }

    errors.empty? ? nil : errors
  end
end
