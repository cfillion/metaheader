require File.expand_path '../helper', __FILE__

class TestParser < MiniTest::Test
  def test_basic_parser
    mh = MetaHeader.new '@hello world'

    assert_equal 'world', mh[:hello]
    assert_equal 1, mh.size
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
    assert_equal 2, mh.size
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
    assert_equal 2, mh.size
  end

  def test_multiline_value
    mh = MetaHeader.new <<-IN
    @test Lorem
      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
    assert_equal 1, mh.size
  end

  def test_multiline_value_variant
    mh = MetaHeader.new <<-IN
    @test
      Lorem
      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
  end

  def test_read_file
    path = File.expand_path '../../lib/metaheader.rb', __FILE__
    mh = MetaHeader.from_file path

    assert_equal 'Hello World', mh[:test]
    assert_equal 1, mh.size
  end
end
