require 'metaheader/version'

class MetaHeader
  REGEX = /\A.*?@(\w+)(?:\s+([^\n]+))?\Z/.freeze

  def self.from_file(file)
    self.new nil
  end

  def initialize(input)
    @data = {}

    input.each_line {|line|
      break if line.strip.empty?
      next unless line =~ REGEX

      @data[$1.to_sym] = $2 || true
    }
  end

  def [](key)
    @data[key]
  end
end
