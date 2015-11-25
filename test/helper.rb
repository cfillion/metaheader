if ENV['CI']
  require 'coveralls'

  Coveralls::Output.silent = true
  Coveralls.wear!
end

require 'metaheader'
require 'minitest/autorun'
