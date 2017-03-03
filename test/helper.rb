require 'simplecov'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
]

SimpleCov.start {
  project_name 'metaheader'
  add_filter '/test/'
}

require 'metaheader'
require 'minitest/autorun'
