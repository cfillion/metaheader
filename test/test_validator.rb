require File.expand_path '../helper', __FILE__

class TestValidator < MiniTest::Test
  def setup
    @mh = MetaHeader.new <<-IN
    @hello world
    @chunky bacon
    IN
  end

  def test_unknown_strict
    @mh.strict = true
    actual = @mh.validate Hash.new

    expected = {
      :unknown => [
        :hello,
        :chunky,
      ],
    }

    assert_equal expected, actual
  end

  def test_unknown_tolerant
    refute @mh.strict
    actual = @mh.validate Hash.new

    assert_nil actual
  end

  def test_optional
    actual = @mh.validate :hello => MetaHeader::OPTIONAL,
      :chunky => MetaHeader::OPTIONAL

    assert_nil actual
  end

  def test_required
    actual = @mh.validate :version => MetaHeader::REQUIRED,
      :hello => MetaHeader::OPTIONAL, :chunky => MetaHeader::OPTIONAL

    expected = {
      :missing => [
        :version,
      ],
    }

    assert_equal expected, actual
  end

  def test_regex
    actual = @mh.validate :hello => /\d+/, :chunky => MetaHeader::OPTIONAL

    expected = {
      :invalid => [
        :hello,
      ],
    }

    assert_equal expected, actual
  end

  def test_regex_missing
    actual = @mh.validate :version => /\d+/,
      :hello => MetaHeader::REQUIRED, :chunky => MetaHeader::OPTIONAL

    expected = {
      :missing => [
        :version,
      ],
    }

    assert_equal expected, actual
  end

  def test_regex_optional
    actual = @mh.validate :version => [MetaHeader::OPTIONAL, /\d+/],
      :hello => MetaHeader::REQUIRED, :chunky => MetaHeader::OPTIONAL

    assert_nil actual
  end

  def test_invalid_rule
    assert_raises ArgumentError do
      @mh.validate_key :hello, :hello => Object.new
    end
  end
end
