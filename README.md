# Parser for metadata header in plain-text files

[![Gem Version](https://badge.fury.io/rb/metaheader.svg)](http://badge.fury.io/rb/metaheader)
[![Build Status](https://travis-ci.org/cfillion/metaheader.svg?branch=master)](https://travis-ci.org/cfillion/metaheader)

## Syntax

```
@key value

@key
  value line 1
  value line 2

@key
@key true

@nokey
@key false
```

Any kind of comment syntax or prefix can be used:

```cpp
/*
 * @key value
 */
```

An alternative syntax is also supported:

```
Key Name: Value
```

Parsing stops at the first empty line (ignoring white space).

## Usage

```ruby
require 'metaheader'

input = '@key value'
mh = MetaHeader.new input

# alternatively:
# mh = MetaHeader.from_file path

# mark unknown keys as invalid
# mh.strict = true

# set @key as mandatory
errors = mh.validate key: MetaHeader::REQUIRED

# other validators are available:
# mh.validate key: MetaHeader::BOOLEAN
# mh.validate key: MetaHeader::OPTIONAL
# mh.validate key: MetaHeader::SINGLELINE
# mh.validate key: MetaHeader::VALUE
# mh.validate key: /^\w{2,}$/
# mh.validate key: proc {|value| 'return nil or error' }

value = mh[:key]
```

## Documentation

MetaHeader's documentation is hosted at
[http://rubydoc.info/gems/metaheader/MetaHeader](http://rubydoc.info/gems/metaheader/MetaHeader).

## Contributing

1. [Fork this repository](https://github.com/cfillion/metaheader/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push -u origin my-new-feature`)
5. Create a new Pull Request
