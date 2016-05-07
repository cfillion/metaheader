require File.expand_path '../helper', __FILE__

class TestValidator < MiniTest::Test
  def validate(input, rules)
    MetaHeader.new(input).validate(rules)
  end

  def test_unknown_strict
    mh = MetaHeader.new "@hello\n@world"
    mh.strict = true

    actual = mh.validate Hash.new
    assert_equal ["unknown tag 'hello'", "unknown tag 'world'"], actual
  end

  def test_unknown_tolerant
    mh = MetaHeader.new "@hello\n@world"
    refute mh.strict

    assert_nil mh.validate(Hash.new)
  end

  def test_strict_optional
    mh = MetaHeader.new "@hello"
    mh.strict = true

    actual = mh.validate \
      hello: MetaHeader::OPTIONAL,
      world: MetaHeader::OPTIONAL

    assert_nil actual
  end

  def test_required
    actual = validate '@foobar', version: MetaHeader::REQUIRED, foobar: []
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

  def test_has_value
    mh = MetaHeader.new '@hello'

    actual = mh.validate :hello => [MetaHeader::VALUE]
    assert_equal ["missing value for tag 'hello'"], actual
  end

  def test_regex
    actual = validate '@hello world', :hello => /\d+/
    assert_equal ["invalid value for tag 'hello'"], actual
  end

  def test_regex_no_value
    mh = MetaHeader.new '@hello'

    actual = mh.validate :hello => [/./]
    assert_equal ["invalid value for tag 'hello'"], actual
  end

  def test_custom_validator
    actual = validate '@hello',
      hello: Proc.new {|value| assert_equal true, value; nil }
    assert_nil actual

    actual = validate '@hello world',
      hello: Proc.new {|value| assert_equal 'world', value; nil }
    assert_nil actual

    actual = validate '@hello', hello: Proc.new {|value| 'Hello World!' }
    assert_equal ["invalid value for tag 'hello': Hello World!"], actual
  end

  def test_error_use_original_case
    actual = validate 'HeLlO: world', hello: /\d+/
    assert_equal ["invalid value for tag 'HeLlO'"], actual
  end

  def test_single_error_per_tag
    actual = validate '@hello', hello: [/\d/, /\d/]
    assert_equal ["invalid value for tag 'hello'"], actual
  end

  def test_invalid_rule
    obj = Object.new.freeze

    error = assert_raises ArgumentError do
      validate '@hello world', hello: obj
    end

    assert_equal "unsupported validator #{obj.inspect}", error.message
  end

  def test_boolean
    actual = validate "@hello\n@hello world",
      hello: MetaHeader::BOOLEAN
    assert_equal ["tag 'hello' cannot have a value"], actual
  end
end
