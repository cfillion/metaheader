require 'metaheader/version'

class MetaHeader
  REGEX = /@(\w+)\s+([^$]+)/.freeze

  def self.from_file(file)
    self.new nil
  end

  def initialize(input)
    @data = {}

    input.each_line {|line|
      break unless line =~ REGEX
      @data[$1.to_sym] = $2
    }
  end

  def [](key)
    @data[key]
  end
end
