# Parser for metadata header in plain-text files

[![Gem Version](https://badge.fury.io/rb/metaheader.svg)](http://badge.fury.io/rb/metaheader)
[![Test status](https://github.com/cfillion/metaheader/workflows/test/badge.svg)](https://github.com/cfillion/metaheader/actions)
[![Donate](https://www.paypalobjects.com/webstatic/en_US/btn/btn_donate_74x21.png)](https://reapack.com/donate)

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

Any kind of comment syntax or prefix can be used (every line of a multiline
value must begin with the same decoration characters):

```cpp
/*
 * @key value
 */
```

An alternative syntax that allows spaces in the key name is also supported:

```
Key: Value
```

Parsing stops at the first empty line outside of a multiline value
(ignoring white space).

## Usage

```ruby
require 'metaheader'

input = '@key value'
mh = MetaHeader.parse input

# alternatively:
# mh = MetaHeader.from_file path

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

MetaHeader's documentation is hosted at <https://rubydoc.info/gems/metaheader/MetaHeader>.

## Contributing

1. [Fork this repository](https://github.com/cfillion/metaheader/fork)
2. Create your feature branch (`git switch -c my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push -u origin my-new-feature`)
5. Create a new Pull Request
