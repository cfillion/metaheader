require File.expand_path '../helper', __FILE__

class TestMultiline < MiniTest::Test
  def test_multiline
    mh = MetaHeader.new <<-IN
    @test Lorem
      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
    assert_equal 1, mh.size
  end

  def test_variant
    mh = MetaHeader.new <<-IN
    @test
      Lorem
      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
  end

  def test_trailing_space
    mh = MetaHeader.new <<-IN
    @hello\x20
      test\x20
    @world\x20\x20
      test\x20
    IN

    assert_equal 'test ', mh[:hello]
    assert_equal 'test ', mh[:world]
  end

  def test_prefix
    mh = MetaHeader.new <<-IN
--    @test Lorem
--      Ipsum
    IN

    assert_equal "Lorem\nIpsum", mh[:test]
    assert_equal 1, mh.size
  end

  def test_wrong_indent
    mh = MetaHeader.new <<-IN
    @test Lorem
    Ipsum
      Test
    IN

    assert_equal 1, mh.size
    assert_equal "Lorem", mh[:test]
  end

  def test_sub_alternate_syntax
    mh = MetaHeader.new <<-IN
    @test Lorem
      Ipsum:
      Dolor: sit amet
    IN

    assert_equal "Lorem\nIpsum:\nDolor: sit amet", mh[:test]
    assert_equal 1, mh.size
  end

  def test_explicit_boolean
    mh = MetaHeader.new <<-IN
    @test true
      test
    IN

    assert_equal "true\ntest", mh[:test]
  end

  def test_empty_line_prefix
    mh = MetaHeader.new <<-IN
    --@test
    --  Hello
    --
    --  World
    --
    --@chunky
    --  bacon
    IN

    assert_equal "Hello\n\nWorld", mh[:test]
    assert_equal 'bacon', mh[:chunky]
  end

  def test_empty_line_prefix_with_space
    mh = MetaHeader.new <<-IN
    -- @test
    --   Hello
    --
    --   World
    IN

    assert_equal "Hello\n\nWorld", mh[:test]
  end

  def test_empty_line
    mh = MetaHeader.new <<-IN
    @test
      Hello

      World
    @chunky bacon

    @foo
    IN

    assert_equal "Hello\n\nWorld", mh[:test]
    assert_equal 'bacon', mh[:chunky]
    assert_nil mh[:foo]
  end

  def test_break_at_empty_line
    mh = MetaHeader.new <<-IN
    -- @hello world

    @chunky bacon
    IN

    assert_equal 'world', mh[:hello]
    assert_nil mh[:chunky]
  end

  def test_alternate_syntax
    mh = MetaHeader.new <<-IN
    -- Hello:
    --   World
    IN

    assert_equal 'World', mh[:hello]
  end
end
