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
      ],
    }

    assert_equal expected, actual
  end

  def test_optional
    actual = @mh.validate :hello => false, :chunky => nil

    assert_nil actual
  end

  def test_required
    actual = @mh.validate :version => true, :hello => false, :chunky => false

    expected = {
      :missing => [
        :version,
      ],
    }

    assert_equal expected, actual
  end

  def test_regex
    actual = @mh.validate :hello => /\d+/, :chunky => nil

    expected = {
      :invalid => [
        :hello,
      ],
    }

    assert_equal expected, actual
  end

  def test_invalid_rule
    assert_raises ArgumentError do
      @mh.validate_key :hello, :hello => Object.new
    end
  end
end
