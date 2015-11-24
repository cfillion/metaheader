require File.expand_path '../helper', __FILE__

class TestValidator < MiniTest::Test
  def setup
    @mh = MetaHeader.new <<-IN
    @hello world
    @chunky bacon
    IN
  end

  def test_unknown
    actual = @mh.validate Hash.new

    expected = {
      :unknown => [
        :hello,
        :chunky,
      ]
    }

    assert_equal expected, actual
  end

  def test_optional
    actual = @mh.validate :hello => false, :chunky => false

    assert_nil actual
  end

  def test_required
    actual = @mh.validate :version => true, :hello => false, :chunky => false

    expected = {
      :missing => [
        :version,
      ]
    }

    assert_equal expected, actual
  end
end
