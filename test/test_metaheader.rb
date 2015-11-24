require File.expand_path '../helper', __FILE__

class TestMetaHeader < MiniTest::Test
  def test_basic_parser
    mh = MetaHeader.new '@hello world'
    assert_equal 'world', mh[:hello]
  end

  def test_unrequired_value
    mh = MetaHeader.new '@hello'
    assert_equal true, mh[:hello]
  end

  def test_ignore_prefix
    mh = MetaHeader.new '-- @chunky bacon'
    assert_equal 'bacon', mh[:chunky]
  end

  def test_multiline
    mh = MetaHeader.new <<-IN
    -- @chunky bacon
    -- @hello world
    IN

    assert_equal 'world', mh[:hello]
    assert_equal 'bacon', mh[:chunky]
  end

  def test_break_empty_line
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
  end
end
