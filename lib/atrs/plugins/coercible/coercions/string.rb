# frozen_string_literal: true

module Atrs
  module Plugins
    module Coercible
      module Coercions
        refine String.singleton_class do
          def coerce(v, _atr)
            case v
            when self then v
            when Integer, Float, Symbol then v.to_s
            when NilClass then nil
            else
              raise UnsupportedError
            end
          end
        end
      end
    end
  end
end