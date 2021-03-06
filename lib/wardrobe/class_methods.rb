# frozen_string_literal: true

require 'forwardable'

module Wardrobe
  module ClassMethods
    extend Forwardable
    def_delegators :@wardrobe_config, :attribute_store, :plugin_store, :option_store

    def self.extended(base)
      Config.create_and_add_to(base)
    end

    # This is called when included in another module/class
    def included(base)
      instance_methods_module.freeze
      if base.class == Module && base.respond_to?(:class_methods_module)
        ddd = class_methods_module
        base.class_methods_module do
          include(ddd)
        end
      end
      class_methods_module.freeze
      unless base.respond_to? :wardrobe_config
        base.include(Wardrobe)
      end
      (plugin_store.store.keys - Wardrobe.config.default_plugins.to_a).each do |plugin|
        base.plugin(plugin) unless base.plugin_store[plugin]
      end
      base.merge_wardrobe_config(wardrobe_config)
      base.instance_methods_module.freeze
      base.class_methods_module.freeze
    end

    def inherited(child)
      instance_methods_module.freeze
      class_methods_module.freeze
      Config.create_and_add_to(child, merge_with: wardrobe_config)
      child.root_config = root_config
    end

    def wardrobe_config(&blk)
      if block_given?
        @wardrobe_config = wardrobe_config.update(&blk)
      else
        @wardrobe_config
      end
    end

    def root_config=(input)
      @root_config = input
    end

    def root_config
      @root_config if instance_variable_defined?(:@root_config)
    end

    def default_getters
      wardrobe_config.default_getters_store.values
    end

    def default_setters
      wardrobe_config.default_setters_store.values
    end

    def add_default_getter(getter)
      @wardrobe_config = wardrobe_config.update do
        @default_getters_store = default_getters_store.add(getter, Wardrobe.getters[getter])
      end
    end

    def add_default_setter(setter)
      @wardrobe_config = wardrobe_config.update do
        @default_setters_store = default_setters_store.add(setter, Wardrobe.setters[setter])
      end
    end

    def merge_wardrobe_config(other_wardrobe_config)
      @wardrobe_config = wardrobe_config.merge(other_wardrobe_config, self)
    end

    def define_getter(atr)
      instance_methods_module do
        define_method(atr.name) do |options: {}, &blk|
          result = atr.getters.inject(nil) do |val, getter|
            getter.block.call(val, atr, self, options)
          end
          result = blk.call(result) if blk
          result
        end
      end
    end

    def instance_methods_module(&blk)
      return wardrobe_config.instance_methods_module unless block_given?
      @wardrobe_config = wardrobe_config.add_instance_methods(self, &blk)
    end

    def class_methods_module(&blk)
      return wardrobe_config.class_methods_module unless block_given?
      @wardrobe_config = wardrobe_config.add_class_methods(self, &blk)
    end

    def define_setter(atr)
      instance_methods_module do
        define_method(atr.setter_name) do |input, options: {}|
          atr.setters.inject(input) do |val, setter|
            setter.block.call(val, atr, self, options)
          end
        end
      end
    end

    def attribute(name, klass, **args, &blk)
      @wardrobe_config = wardrobe_config.add_attribute(
        name, klass, self, **args, &blk
      )
      define_getter(attribute_store[name])
      define_setter(attribute_store[name])
    end

    def attributes(**kargs, &blk)
      BlockSetup.new(self).run(**kargs, &blk)
    end

    def remove_attributes(*wardrobe)
      wardrobe.each do |name|
        @wardrobe_config = wardrobe_config.remove_attribute(name)
      end
    end

    alias remove_attribute remove_attributes

    def plugin(name, **args)
      name = name.to_sym
      @wardrobe_config = wardrobe_config.enable_plugin(name, **args)
      plugin = plugin_store[name][:klass]
      plugin.required_plugins.each do |required_plugin_name|
        plugin(required_plugin_name) unless plugin_store[required_plugin_name]
      end
      init_plugin_methods(plugin)
      plugin.after_load&.call(self, **args)
    end

    def init_plugin_methods(plugin)
      if plugin.const_defined?(:ClassMethods)
        extend(plugin.const_get(:ClassMethods))
      end

      if plugin.const_defined?(:InstanceMethods)
        include(plugin.const_get(:InstanceMethods))
      end

      # Currently these are not needed
      #
      # if plugin.const_defined?(:AttributeClassMethods)
      #   Attribute.extend(plugin.const_get(:AttributeClassMethods))
      # end
      #
      # if plugin.const_defined?(:AttributeInstanceMethods)
      #   Attribute.include(plugin.const_get(:AttributeInstanceMethods))
      # end
    end
  end
end
