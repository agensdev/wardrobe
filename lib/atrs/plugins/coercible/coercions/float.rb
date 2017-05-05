# frozen_string_literal: true

module Atrs
  module Plugins
    module Coercible
      module Coercions
        refine Float.singleton_class do
          def coerce(v, _atr)
            case v
            when self then v
            when String, Integer then v.to_f
            when Time then v.to_f
            when Date then v.to_time.to_f
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
