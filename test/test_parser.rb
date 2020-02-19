require File.expand_path '../helper', __FILE__

class TestParser < MiniTest::Test
  def test_basic_parser
    mh = MetaHeader.new '@hello world'

    assert_equal 'world', mh[:hello]
    assert_equal 1, mh.size
  end

  def test_set_value
    mh = MetaHeader.new String.new

    assert_empty mh
    mh[:hello] = 'world'
    assert_equal 'world', mh[:hello]
    refute_empty mh

    mh[:hello] = 'bacon'
    assert_equal 'bacon', mh[:hello]
    assert_equal 1, mh.size

    error = assert_raises(ArgumentError) { mh[:hello] = nil }
    assert_equal 'value cannot be nil', error.message
  end

  def test_implicit_boolean
    mh = MetaHeader.new "@hello"
    assert_equal true, mh[:hello]
  end

  def test_explicit_boolean
    mh = MetaHeader.new "@foo true\n@bar false"
    assert_equal true, mh[:foo]
    assert_equal false, mh[:bar]
  end

  def test_ignore_prefix
    mh = MetaHeader.new '-- @chunky bacon'
    assert_equal 'bacon', mh[:chunky]
  end

  def test_two_tags
    mh = MetaHeader.new <<-IN
    -- @chunky bacon
    -- @hello world
    IN

    assert_equal 'world', mh[:hello]
    assert_equal 'bacon', mh[:chunky]
    assert_equal 2, mh.size
  end

  def test_break_at_empty_line
    mh = MetaHeader.new <<-IN
    @hello world
\x20
    @chunky bacon
    IN

    assert_equal 'world', mh[:hello]
    assert_nil mh[:chunky]
  end

  def test_ignore_c_comment_tokens
    mh = MetaHeader.new <<-IN
/*
    -- @hello world
*/
/*
    @chunky bacon
*/
    IN

    assert_equal 'world', mh[:hello]
    assert_equal 'bacon', mh[:chunky]
    assert_equal 2, mh.size
  end

  def test_trailing_whitespace
    mh = MetaHeader.new '@hello world   '
    assert_equal 'world', mh[:hello]
  end

  def test_empty_prefixed_line
    mh = MetaHeader.new <<-IN
    -- @first
    --
    -- @second
    IN

    refute_nil mh[:second]
  end

  def test_read_file
    path = File.expand_path '../input/basic_tag', __FILE__
    mh = MetaHeader.from_file path

    assert_equal 'Hello World', mh[:test]
    assert_equal 1, mh.size
  end

  def test_to_hash
    mh = MetaHeader.new '@key value'
    assert_equal Hash[key: 'value'], mh.to_h
  end

  def test_alternate_syntax
    mh = MetaHeader.new 'Key Test: value'
    assert_equal Hash[key_test: 'value'], mh.to_h
  end

  def test_alternate_syntax_prefix
    mh = MetaHeader.new '-- Key Test: Value'
    assert_equal Hash[key_test: 'Value'], mh.to_h
  end

  def test_crlf_newlines
    mh = MetaHeader.new "key: value\r\n@run_custom"
    assert_equal 'value', mh[:key]
    assert_equal true, mh[:run_custom]
  end

  def test_alternate_syntax_trailing_space
    mh = MetaHeader.new ' Key Test : Value'
    assert_equal Hash[key_test: 'Value'], mh.to_h
  end

  def test_alternate_syntax_compact
    mh = MetaHeader.new 'Key Test:Value'
    assert_equal Hash[key_test: 'Value'], mh.to_h
  end

  def test_alternate_syntax_no_value
    mh = MetaHeader.new 'Key Test:'
    assert_equal Hash.new, mh.to_h
  end

  def test_inspect
    mh = MetaHeader.new '@hello world'

    hash = {hello: 'world'}
    assert_equal "#<MetaHeader #{hash.inspect}>", mh.inspect
  end

  def test_has_tag
    mh = MetaHeader.new '@hello'
    assert_equal true, mh.has?(:hello)
    assert_equal false, mh.has?(:world)
  end

  def test_default_value
    mh = MetaHeader.new String.new
    assert_equal 'world', mh[:hello, 'world']
  end

  def test_delete
    mh = MetaHeader.new '@hello world'
    assert mh.has?(:hello)
    mh.delete :hello
    refute mh.has?(:hello)
  end

  def test_construct_from_instance
    mh = MetaHeader.new '@hello world'
    assert_same mh, MetaHeader.parse(mh)
    assert_equal mh.to_h, MetaHeader.parse('@hello world').to_h
  end

  def test_alias
    mh = MetaHeader.new '@a 1'
    mh.alias :a, :b
    refute mh.has?(:a)
    assert_equal '1', mh[:b]

    mh[:d] = '2'
    mh.alias :c, :d
    refute mh.has?(:c)
    assert_equal '2', mh[:d]
  end

  def test_alias_hash
    mh = MetaHeader.new "@a 1\n@b 2"
    mh.alias a: :c, b: :d
    assert_equal '1', mh[:c]
    assert_equal '2', mh[:d]
  end

  def test_alias_array
    mh = MetaHeader.new "@a 1\n@b 2"
    mh.alias [:a, :b, :c], :d
    assert [:a, :b, :c].none? {|t| mh.has? t }
    assert_equal '2', mh[:d]
  end

  def test_alias_invalid_args
    mh = MetaHeader.new "@a 1\n@b 2"
    assert_raises(ArgumentError) { mh.alias }
    assert_raises(ArgumentError) { mh.alias 1, 2, 3 }
  end

  def test_utf16_bom
    mh = MetaHeader.new "\xff\xfe@a b\n"
    assert_equal 'b', mh[:a]
  end
end
