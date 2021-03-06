require 'test_helper'

class ValidationPredicatesEvenTest < TestBase
  class Foo
    include Wardrobe
    plugin :validation
    attribute :integer, Integer, validates { even? }
  end

  def test_nil
    no_log do
      assert_raises(NoMethodError) {
        Foo.new(
        integer: nil
        )._validation_errors
      }
    end
  end

  def test_fail
    errors = Foo.new(
      integer: 1
    )._validation_errors

    assert_equal 'must be even', errors[:integer][0]
  end

  def test_success
    errors = Foo.new(
      integer: 2
    )._validation_errors

    refute errors.has_key?(:integer)
  end
end
