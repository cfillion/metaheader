# Parser for metadata header in plain-text files

[![Build Status](https://travis-ci.org/cfillion/metaheader.svg?branch=master)](https://travis-ci.org/cfillion/metaheader)

## Syntax

```
@key value

@key
  value line 1
  value line 2

@key
```

Any kind of comment syntax or prefix is supported:

```cpp
/*
 * @key value
 */
```

Parsing stops at the first empty line (ignoring white space).

## Usage

```ruby
require 'metaheader'

input = '@key value'
mh = MetaHeader.new input

# alternatively:
# mh = MetaHeader.from_file path

# set @key as not required
errors = mh.validate :key => nil

# or set @key as required:
# mh.validate :key => true
#
# ensure @key contains a valid value with a regex
# mh.validate :key => /^\w{2,}$/

value = mh[:key]
```
