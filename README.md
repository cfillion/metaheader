# Parser for metadata header in plain-text files

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

# or set @key as required:
# mh.validate :key => MetaHeader::REQUIRED
#
# ensure @key contains a valid value with a regex
# mh.validate :key => /^\w{2,}$/

value = mh[:key]
```
