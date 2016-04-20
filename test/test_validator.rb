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
    assert_equal ["unknown tag 'hello'", "unknown tag 'chunky'"], actual
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

    assert_equal ["missing tag 'version'"], actual
  end

  def test_singleline
    mh = MetaHeader.new <<-IN
    @hello
      chunky
      bacon
    @world
      foo
      bar
    IN

    actual = mh.validate :hello => MetaHeader::SINGLELINE
    assert_equal ["tag 'hello' must be singleline"], actual
  end

  def test_regex
    actual = @mh.validate :hello => /\d+/, :chunky => MetaHeader::OPTIONAL
    assert_equal ["invalid value for tag 'hello'"], actual
  end

  def test_use_original_format
    mh = MetaHeader.new 'HeLlO: world'
    actual = mh.validate :hello => /\d+/
    assert_equal ["invalid value for tag 'HeLlO'"], actual
  end

  def test_regex_missing
    actual = @mh.validate :version => /\d+/
    assert_equal ["missing tag 'version'"], actual
  end

  def test_regex_optional
    actual = @mh.validate :version => [MetaHeader::OPTIONAL, /\d+/],
      :hello => MetaHeader::REQUIRED, :chunky => MetaHeader::OPTIONAL

    assert_nil actual
  end

  def test_regex_no_value
    mh = MetaHeader.new '@hello'

    actual = mh.validate :hello => [MetaHeader::OPTIONAL, /.+/]
    assert_equal ["invalid value for tag 'hello'"], actual
  end

  def test_custom_validator
    valid = @mh.validate :hello => Proc.new {|value| value == 'world' && nil }
    assert_nil valid

    invalid = @mh.validate :hello => Proc.new {|value| 'Hello World!' }
    assert_equal ["invalid value for tag 'hello': Hello World!"], invalid
  end

  def test_invalid_rule
    assert_raises ArgumentError do
      @mh.validate_key :hello, :hello => Object.new
    end
  end
end
