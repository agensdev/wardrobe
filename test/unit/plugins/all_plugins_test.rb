require 'test_helper'

class AllPluginsTest < TestBase

  class PluginsWithMiddleware
    include Wardrobe
    plugin :default
    plugin :dirty_tracker
    plugin :optional_getter
    plugin :optional_setter
    plugin :nil_if_empty
    plugin :nil_if_zero

    attribute :foo, String, nil_if_zero: true, nil_if_empty: true, default: 5
  end

  def test_one
    assert_nil PluginsWithMiddleware.new(foo: '').foo
    assert_nil PluginsWithMiddleware.new(foo: 0).foo
    assert_equal '5', PluginsWithMiddleware.new().foo
    assert_equal 'Bar', PluginsWithMiddleware.new(foo: 'Bar').foo
  end
end
