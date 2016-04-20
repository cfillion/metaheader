# Parser for metadata header in plain-text files

[![Gem Version](https://badge.fury.io/rb/metaheader.svg)](http://badge.fury.io/rb/metaheader)
[![Build Status](https://travis-ci.org/cfillion/metaheader.svg?branch=master)](https://travis-ci.org/cfillion/metaheader)
[![Coverage Status](https://coveralls.io/repos/cfillion/metaheader/badge.svg?branch=master&service=github)](https://coveralls.io/github/cfillion/metaheader?branch=master)

## Syntax

```
@key value

@key
  value line 1
  value line 2

@key
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

# set @key as optional
errors = mh.validate :key => MetaHeader::OPTIONAL

# other validators are available:
# mh.validate :key => MetaHeader::REQUIRED
# mh.validate :key => MetaHeader::SINGLELINE
# mh.validate :key => MetaHeader::HAS_VALUE
# mh.validate :key => /^\w{2,}$/
# mh.validate :key => proc {|value| 'return nil or error' }

value = mh[:key]
```
