require File.expand_path '../helper', __FILE__

class TestMetaHeader < MiniTest::Test
  def test_basic_parser
    mh = MetaHeader.new '@hello world'
    assert_equal 'world', mh[:hello]
  end
end
