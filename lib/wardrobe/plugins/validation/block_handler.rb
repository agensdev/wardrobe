module Wardrobe
  module Plugins
    module Validation
      class CustomHash < Hash
        def initialize(**args)
          merge!(args)
        end

        def &(other)
          if self[:and]
            self[:and] << other
            self
          else
            self.class.new(and: [self, other])
          end
        end

        def |(other)
          self.class.new(or: [self, other])
        end
      end

      METHODS_WITHOUT_ARGUMENTS = [
        :empty?,
        :filled?,
        :odd?,
        :even?
      ]

      METHODS_WITH_ARGUMENTS = [
        :format?,
        :size?,
        :min_size?,
        :max_size?,
        :included_in?,
        :excluded_from?,
        :gt?,
        :lt?,
        :lteq?,
        :gteq?
      ]

      METHODS_WITH_BLOCK = [
        :each,
        :each_key,
        :each_value
      ]

      TYPE_METHODS = {
        str?: String,
        sym?: Symbol,
        int?: Integer,
        float?: Float,
        bool?: Boolean,
        date?: Date,
        time?: Time,
        date_time?: DateTime,
        array?: Array,
        hash?: Hash
      }

      class BlockHandler
        attr_reader :result

        def initialize(&blk)
          @result = instance_exec(&blk)
        end

        private

        TYPE_METHODS.each do |name, klass|
          define_method(name) do
            CustomHash.new(type?: klass)
          end
        end

        METHODS_WITHOUT_ARGUMENTS.each do |name|
          define_method(name) do
            CustomHash.new(name => nil)
          end
        end

        METHODS_WITH_ARGUMENTS.each do |name|
          define_method(name) do |value|
            CustomHash.new(name => value)
          end
        end

        METHODS_WITH_BLOCK.each do |name|
          define_method(name) do |&blk|
            raise "Error. No block given" unless blk
            CustomHash.new(name => instance_exec(&blk))
          end
        end
      end
    end
  end
end