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
