require File.expand_path '../helper', __FILE__

class CustomParser < MetaHeader::Parser
  def self.reset
    @@called = false
  end

  def self.called?
    @@called
  end

  def self.input
    @@input
  end

  def self.instance
    @@instance
  end

  def parse(input)
    return unless header[:run_custom]

    header[:hello] = header[:hello].to_s * 2

    @@input = input
    @@instance = header
    @@called = true
  end
end

class TestParser < MiniTest::Test
  def setup
    CustomParser.reset
  end

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
    -- @hello world

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

  def test_multiline
    mh = MetaHeader.new <<-IN
    @test Lorem
      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
    assert_equal 1, mh.size
  end

  def test_multiline_variant
    mh = MetaHeader.new <<-IN
    @test
      Lorem
      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
  end

  def test_multiline_trailing_space
    mh = MetaHeader.new <<-IN
    @hello\x20
      test\x20
    @world\x20\x20
      test\x20
    IN

    assert_equal 'test', mh[:hello]
    assert_equal 'test', mh[:world]
  end

  def test_multiline_prefix
    mh = MetaHeader.new <<-IN
--    @test Lorem
--      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
    assert_equal 1, mh.size
  end

  def test_multiline_wrong_indent
    mh = MetaHeader.new <<-IN
    @test Lorem
    Ipsum
      Test
    IN

    assert_equal 1, mh.size
    assert_equal "Lorem", mh[:test]
  end

  def test_multiline_sub_alternate_syntax
    mh = MetaHeader.new <<-IN
    @test Lorem
      Ipsum:
      Dolor: sit amet
    IN

    assert_equal "Lorem\nIpsum:\nDolor: sit amet", mh[:test]
    assert_equal 1, mh.size
  end

  def test_multiline_explicit_boolean
    mh = MetaHeader.new <<-IN
    @test true
      test
    IN

    assert_equal "true\ntest", mh[:test]
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

  def test_windows_newlines
    mh = MetaHeader.new "key: value\r\n@run_custom"
    assert_equal 'value', mh[:key]
    assert_equal "key: value\n@run_custom", CustomParser.input
  end

  def test_alternate_syntax_trailing_space
    mh = MetaHeader.new ' Key Test : Value'
    assert_equal Hash[key_test: 'Value'], mh.to_h
  end

  def test_inspect
    mh = MetaHeader.new '@hello world'

    hash = {hello: 'world'}
    assert_equal "#<MetaHeader #{hash.inspect}>", mh.inspect
  end

  def test_default_parser_implementation
    assert_raises NotImplementedError do
      MetaHeader::Parser.new.parse String.new
    end
  end

  def test_transform_from_text
    input = "@run_custom\nHello\n\nWorld".freeze

    mh = MetaHeader.new input

    assert CustomParser.called?
    assert_equal input, CustomParser.input
    assert_same mh, CustomParser.instance
  end

  def test_transform_from_file
    path = File.expand_path '../input/custom_parser', __FILE__

    mh = MetaHeader.from_file path
    assert_equal 'worldworld', mh[:hello]

    assert CustomParser.called?
    assert_equal File.read(path), CustomParser.input
    assert_same mh, CustomParser.instance
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
  end
end
