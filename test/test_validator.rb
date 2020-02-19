require File.expand_path '../helper', __FILE__

class TestValidator < MiniTest::Test
  def validate(input, rules)
    MetaHeader.parse(input).validate(rules)
  end

  def test_unknown_strict
    mh = MetaHeader.parse "@hello\n@WORLD"
    errors = mh.validate Hash.new, true
    assert_equal ["unknown tag 'hello'", "unknown tag 'WORLD'"], errors
  end

  def test_unknown_tolerant
    mh = MetaHeader.parse "@hello\n@world"
    assert_empty mh.validate(Hash.new, false)
  end

  def test_strict_optional
    rules = {
      hello: MetaHeader::OPTIONAL,
      world: MetaHeader::OPTIONAL,
    }

    mh = MetaHeader.parse "@hello"
    errors = mh.validate rules, true
    assert_empty errors
  end

  def test_required
    errors = validate '@foobar', version: MetaHeader::REQUIRED, foobar: []
    assert_equal ["missing tag 'version'"], errors
  end

  def test_singleline
    mh = MetaHeader.parse <<-IN
    @hello
      chunky
      bacon
    @world
      foo
      bar
    IN

    errors = mh.validate :hello => MetaHeader::SINGLELINE
    assert_equal ["tag 'hello' must be singleline"], errors
  end

  def test_has_value
    mh = MetaHeader.parse '@hello'

    errors = mh.validate :hello => [MetaHeader::VALUE]
    assert_equal ["missing value for tag 'hello'"], errors
  end

  def test_regex
    errors = validate '@hello world', :hello => /\d+/
    assert_equal ["invalid value for tag 'hello'"], errors
  end

  def test_regex_no_value
    mh = MetaHeader.parse '@hello'

    errors = mh.validate :hello => [/./]
    assert_equal ["invalid value for tag 'hello'"], errors
  end

  def test_custom_validator
    errors = validate '@hello',
      hello: Proc.new {|value| assert_equal true, value; nil }
    assert_empty errors

    errors = validate '@hello world',
      hello: Proc.new {|value| assert_equal 'world', value; nil }
    assert_empty errors

    errors = validate '@hello', hello: Proc.new {|value| 'Hello World!' }
    assert_equal ["invalid value for tag 'hello': Hello World!"], errors
  end

  def test_error_use_original_case
    errors = validate 'HeLlO: world', hello: /\d+/
    assert_equal ["invalid value for tag 'HeLlO'"], errors
  end

  def test_single_error_per_tag
    errors = validate '@hello', hello: [/\d/, /\d/]
    assert_equal ["invalid value for tag 'hello'"], errors
  end

  def test_invalid_rule
    obj = Object.new.freeze

    error = assert_raises ArgumentError do
      validate '@hello world', hello: obj
    end

    assert_equal "unsupported validator #{obj.inspect}", error.message
  end

  def test_boolean
    errors = validate "@hello true\n@hello world",
      hello: MetaHeader::BOOLEAN
    assert_equal ["tag 'hello' cannot have a value"], errors
  end

  def test_alias
    mh = MetaHeader.parse "@a"
    mh.alias :a, :b
    assert_equal ["missing value for tag 'a'"],
      mh.validate(b: [MetaHeader::REQUIRED, MetaHeader::VALUE])
  end
end
